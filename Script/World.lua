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
local World = {}
World.__index = World

local _currentInstance = nil

-- Singleton Access
function World.getInstance()
    if not _currentInstance then
        _currentInstance = setmetatable({}, World)
        _currentInstance:init()
    end
    return _currentInstance
end

function World:init()
    self._views = {}
    self._entities = {}
    self._systems = {}
    self._dirtyEntities = {}
    self._pendingAdds = {}
    self._pendingRemoves = {}
    self._pendingDestruction = {}
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

-- Temporary placeholder for Phase 2/3 methods to allow compilation/loading
function World:registerSystem(system) end
function World:unregisterSystem(system) end
function World:addEntity(entity) end
function World:removeEntity(entity) end
function World:update(dt) end
function World:draw() end

return World
