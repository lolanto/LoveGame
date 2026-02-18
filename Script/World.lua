local ComponentsView = require('ComponentsView')

---@class World
---@field _instance World
---@field _views table<string, ComponentsView> Cache of active views
---@field _entities table<string, Entity> All active entities (ID -> Entity)
---@field _systems table<string, BaseSystem> Registered systems
---@field _dirtyEntities table<string, Entity> Entities needing archetype update
---@field _pendingAdds Entity[]
---@field _pendingRemoves Entity[]
---@field _pendingDestruction Entity[] (Zombie State)
---@field _mainCharacter Entity|nil
---@field _mainCamera Entity|nil
local World = {}
World.__index = World
World.static = {}
World.static.instance = nil

function World.static.getInstance()
    if World.static.instance == nil then
        World.static.instance = World:new()
    end
    return World.static.instance
end

function World:new()
    assert(World.static.instance == nil, "World is a singleton!")
    local instance = setmetatable({}, World)
    instance:init()
    return instance
end

function World:reset()
    self:init()
end

function World:init()
    self._views = {}
    self._entities = {}
    self._systems = {}
    self._dirtyEntities = {}
    self._pendingAdds = {}
    self._pendingAddSet = {} -- Set for O(1) checking
    self._pendingRemoves = {}
    self._pendingRemoveSet = {} -- Set for O(1) checking
    self._pendingDestruction = {} -- Zombie State list
    self._pendingDestructionSet = {} -- Set for O(1) checking
    self._collisionEvents = {} -- T037 Collision Events
    self._mainCharacter = nil
    self._mainCamera = nil
end

--- Mark an entity as needing archetype re-evaluation
---@param entity Entity
function World:markEntityDirty(entity)
    local id = entity:getID_const()
    -- Only track if managed/active
    if not self._dirtyEntities[id] then
        self._dirtyEntities[id] = entity
    end
end

--- Retrieves or creates a ComponentsView for the given requirements
---@param requiredComponentInfos table<string, ComponentRequirementDesc>
---@return ComponentsView
function World:getComponentsView(requiredComponentInfos)
    -- 1. Generate Canonical Key
    local key = ComponentsView.generateKey(requiredComponentInfos)
    
    -- 2. Check Cache
    if self._views[key] then
        return self._views[key]
    end
    
    -- 3. Create New View
    local newView = ComponentsView:new(key, requiredComponentInfos)
    self._views[key] = newView
    
    -- 4. Initial Population (Naive scan of all entities - optimization: only do this if world already has entities)
    -- For now, we assume views are requested at startup before entities exist
    for _, entity in pairs(self._entities) do
        newView:add(entity)
    end
    
    return newView
end

function World:registerSystem(system)
    self._systems[system._nameOfSystem] = system
    -- Note: Systems should ideally initialize their view during creation, but as a safeguard we could ensure it here
    -- system:initView() 
end
function World:unregisterSystem(system)
    self._systems[system._nameOfSystem] = nil
end

function World:addEntity(entity)
    local id = entity:getID_const()

    -- 1. Idempotency Check: Already Active (and not pending removal)
    if self._entities[id] and not self._pendingRemoveSet[id] then
        return
    end

    -- 2. Idempotency Check: Already Pending Add
    if self._pendingAddSet[id] then
        return
    end
    local updatePendingAdd = true
    -- 3. Cancellation: If pending removal, cancel it
    if self._pendingRemoveSet[id] then
        -- Cancel removal: Remove from set so clean() skips it
        self._pendingRemoveSet[id] = nil
        -- Ensure World reference is restored if it was cleared
        entity:setWorld(self)
        updatePendingAdd = false -- Already in entities, just cancel pending remove, no need to re-adds
    end

    -- 4. Resurrection: If pending destruction (Zombie), bring back
    if self._pendingDestructionSet[id] then
        self._pendingDestructionSet[id] = nil
        -- Remove from actual list happens in clean() via set check or we just re-add it now and let clean handle it?
        -- Simplest: Treat as new add, clean() will see it's not in entities yet. 
        -- But we need to ensure it's removed from pendingDestruction list eventually. 
        -- We'll handle that by rebuilding pendingDestruction in clean().
    end

    -- 5. Standard Add
    entity:setWorld(self)
    if updatePendingAdd then
        table.insert(self._pendingAdds, entity)
        self._pendingAddSet[id] = true
    end

    local children = entity:getChildren()
    for _, child in pairs(children) do
        self:addEntity(child) -- Recursively queue children for addition
    end
end

--- Recursively requests removal of entity and its children
---@param entity Entity
function World:removeEntity(entity)
    local id = entity:getID_const()

    if not self._entities[id] then
        return
    end
    -- 1. Idempotency Check: Already Pending Remove
    if self._pendingRemoveSet[id] then
        return
    end

    local updatePendingRemove = true
    -- 2. Cancellation: If Pending Add, cancel it
    if self._pendingAddSet[id] then
        self._pendingAddSet[id] = nil
        updatePendingRemove = false -- Not in entities yet, just cancel pending add, no need to queue remove
    end

    -- 3. Standard Remove (if strictly active)
    entity:setWorld(nil) -- Clear World reference immediately
    if updatePendingRemove then
        table.insert(self._pendingRemoves, entity)
        self._pendingRemoveSet[id] = true
    end

    local children = entity:getChildren()
    for _, child in pairs(children) do
        self:removeEntity(child)
    end
end

--- Frame clean-up phase: Add queued entities, Remove marked ones
function World:clean()
    -- 1. Process Pending Adds
    for _, entity in ipairs(self._pendingAdds) do
        local id = entity:getID_const()
        if not self._entities[id] then
            self._entities[id] = entity
            -- Notify all views
            for _, view in pairs(self._views) do
                view:add(entity)
            end
        end
    end
    self._pendingAdds = {}
    self._pendingAddSet = {} -- Clear Set

    -- 2. Process Dirty Entities (Deferred Archetype Update)
    for id, entity in pairs(self._dirtyEntities) do
        -- Only process if entity is still tracked and fully setup
        -- Optimization: Could check pendingRemoves set, but cleaner to just check if valid
        if self._entities[id] then
             entity:setIsArchDirty(false)
             
             for _, view in pairs(self._views) do
                 -- Re-evaluate membership for this view
                 -- 1. Try to remove (if it was there and now invalid, or valid but needs refresh)
                 -- 2. Try to add (if it fits requirements)
                 view:remove(entity)
                 view:add(entity)
             end
        end
    end
    self._dirtyEntities = {}

    -- 3. Process Pending Removes
    for _, entity in ipairs(self._pendingRemoves) do
        local id = entity:getID_const()
        -- Only process if it is in the world as managed/active
        if self._entities[id] then
            -- Remove from main active list
            self._entities[id] = nil
            
            -- Remove from all Views (Systems should no longer see it)
            for _, view in pairs(self._views) do
                view:remove(entity)
            end
            
            -- Move to Pending Destruction (Zombie State check)
            table.insert(self._pendingDestruction, entity)
            self._pendingDestructionSet[id] = true
        end
    end
    self._pendingRemoves = {}
    self._pendingRemoveSet = {} -- Clear Set
    
    -- 4. Garbage Collection Tick for Zombies
    local rw_index = 1
    -- Reset set for compaction
    self._pendingDestructionSet = {}
    
    for i = 1, #self._pendingDestruction do
        local entity = self._pendingDestruction[i]
        local id = entity:getID_const()
        
        -- Check if resurrected (active in world again)
        if entity:getRefCount_const() <= 0 then
            -- Safe to destroy completely
            if entity.destroy then
                entity:destroy() -- Release resources if any
            end
            -- Do not keep in list
        else
            -- Still held by something (TimeRewind?), keep in zombie list
            if rw_index ~= i then
                self._pendingDestruction[rw_index] = entity
            end
            self._pendingDestructionSet[id] = true
            rw_index = rw_index + 1
        end
    end
    -- Nil out remaining slots to help GC
    for i = rw_index, #self._pendingDestruction do
        self._pendingDestruction[i] = nil
    end
    
    -- 5. Clear Collision Events
    self._collisionEvents = {}
end

--- Retrieves the complete list of valid entities (including disabled)
---@return Entity[]
function World:getAllManagedEntities()
    -- Performance note: This recreates table every call. 
    -- If called frequently, we might cache this and invalidate on add/remove.
    local list = {}
    for _, entity in pairs(self._entities) do
        table.insert(list, entity)
    end
    return list
end

--- Retrieves the list of currently ENABLED entities
---@return Entity[]
function World:getActiveEntities()
    local list = {}
    for _, entity in pairs(self._entities) do
        if entity:isEnable_const() then
            table.insert(list, entity)
        end
    end
    return list
end

---@param event table {a:Entity, b:Entity, type:string, contact:Contact}
function World:recordCollisionEvent(event)
    table.insert(self._collisionEvents, event)
end

---@return table[]
function World:getCollisionEvents()
    return self._collisionEvents or {}
end

---@return table<string, Entity>
function World:getAllEntities()
    return self._entities
end

---@param systemName string
---@return BaseSystem
function World:getSystem(systemName)
    return self._systems[systemName]
end

---@param entity Entity|nil
function World:setMainCharacter(entity)
    self._mainCharacter = entity
end

---@return Entity|nil
function World:getMainCharacter()
    return self._mainCharacter
end

---@param entity Entity|nil
function World:setMainCamera(entity)
    self._mainCamera = entity
end

---@return Entity|nil
function World:getMainCamera()
    return self._mainCamera
end

function World:update(dt, userInteractController)
    self:clean()

    -- Auto-detect Main Character/Camera if missing (Legacy support)
    if not self._mainCharacter or not self._mainCamera then
        for _, entity in pairs(self._entities) do
             if not self._mainCharacter and entity:hasComponent('MainCharacterControllerCMP') then
                 self._mainCharacter = entity
             end
             if not self._mainCamera and entity:hasComponent('CameraCMP') then
                 self._mainCamera = entity
             end
        end
    end

    local timeRewindSys = self:getSystem('TimeRewindSys')
    local blackHoleSys = self:getSystem('BlackHoleSys')
    local timeDilationSys = self:getSystem('TimeDilationSys')
    local mainCharSys = self:getSystem('MainCharacterInteractSys')
    local patrolSys = self:getSystem('PatrolSys')
    local entityMovementSys = self:getSystem('EntityMovementSys')
    local transformSys = self:getSystem('TransformUpdateSys')
    local physicSys = self:getSystem('PhysicSys')
    local triggerSys = self:getSystem('TriggerSys')
    local cameraSetupSys = self:getSystem('CameraSetupSys')
    
    local mainCharacterEntity = self:getMainCharacter()
    if mainCharacterEntity ~= nil then
        local mainCharCtrlCmp = mainCharacterEntity:getComponent('MainCharacterControllerCMP')
        if mainCharCtrlCmp ~= nil then
            mainCharCtrlCmp:update(dt, userInteractController)
        end
    end
    
    if userInteractController then
        timeDilationSys:processUserInput(userInteractController)
        blackHoleSys:processUserInput(userInteractController)
        timeRewindSys:processUserInput(userInteractController)
    end

    -- Time Rewind Collection (Snapshot)
    timeRewindSys:preCollect()
    local managedEntities = self:getAllManagedEntities()
    for _, entity in ipairs(managedEntities) do
        timeRewindSys:collect(entity)
    end

    timeDilationSys:tick(dt)
    timeRewindSys:tick(dt)
    
    if timeRewindSys:getIsRewinding() then
        -- Review Mode
        transformSys:tick(dt)
        timeRewindSys:postProcess()
    else
        mainCharSys:tick(dt)
        patrolSys:tick(dt)
        blackHoleSys:tick(dt)
        entityMovementSys:tick(dt)
        transformSys:tick(dt)

        physicSys:tick(dt)
        transformSys:tick(dt) -- Re-update after physics
        triggerSys:tick(dt)
    end
    
    local displaySys = self:getSystem('DisplaySys')
    if displaySys then
        displaySys:tick(dt)
    end
    
    cameraSetupSys:tick(dt)
end

function World:draw()
    local displaySys = self:getSystem('DisplaySys')
    if displaySys then
        displaySys:draw()
    end
end

return { World = World }
