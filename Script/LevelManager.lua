local MUtils = require('MUtils')
local LOG_MODULE = "LevelManager"
MUtils.RegisterModule(LOG_MODULE)

local MessageCenter = require('MessageCenter').MessageCenter
local IBroadcaster = require('EventInterfaces').IBroadcaster

local Event_LevelLoaded = MessageCenter.static.getInstance():registerEvent("Event_LevelLoaded")
local Event_LevelUnloaded = MessageCenter.static.getInstance():registerEvent("Event_LevelUnloaded")

--- @class LevelManager : IBroadcaster
--- @field _currentLevel Level|nil 当前加载的关卡
--- @field _previousLevel Level|nil 上一个关卡
--- @field _nextLevelModule Level|nil 下一个关卡模块（预加载用）
--- @field _unloadLevelsList table 需要卸载的关卡列表
local LevelManager = setmetatable({}, IBroadcaster)
LevelManager.__index = LevelManager
LevelManager.static = {}
LevelManager.static.instance = nil

LevelManager.static.getInstance = function()
    if LevelManager.static.instance == nil then
        LevelManager.static.instance = LevelManager:new()
    end
    return LevelManager.static.instance
end

function LevelManager:new()
    --- 只能有一个单例
    assert(LevelManager.static.instance == nil, "LevelManager 只能有一个实例！")
    
    
    -- 继承自 IBroadcaster
    local instance = IBroadcaster:new("LevelManager")
    setmetatable(instance, LevelManager)
    
    instance._currentLevel = nil
    instance._previousLevel = nil
    instance._nextLevelModule = nil
    instance._unloadLevelsList = {}
    instance._pendingSpawnEntities = {}
    return instance
end

function LevelManager:spawnEntity(entity)
    table.insert(self._pendingSpawnEntities, entity)
end

function LevelManager:getCurrentLevel()
    return self._currentLevel
end

-- T003: Load data file with sandboxing
function LevelManager:_loadDataFile(path)
    local chunk, err = loadfile(path)
    if not chunk then
        MUtils.Error(LOG_MODULE, "Failed to load level data file: " .. path .. " Error: " .. tostring(err))
        return nil
    end

    -- Sandbox environment: whitelist only what's needed
    local env = {
        -- Basic types and table manipulation rely on global metatables or basic constructor syntax
        -- If data files use table.insert etc, we might need to expose them.
        -- For now, data files are pure table returns, so empty env is mostly fine.
        -- But if they use {1, 2, 3}, that's fine.
    }
    setfenv(chunk, env)
    
    local success, result = pcall(chunk)
    if not success then
        MUtils.Error(LOG_MODULE, "Failed to execute level data file: " .. path .. " Error: " .. tostring(result))
        return nil
    end
    return result
end

-- T004: Resolve component class from name
function LevelManager:_resolveComponent(className)
    local searchPaths = {
        'Component.',
        'Component.DrawableComponents.',
        'Component.Gameplay.',
        ''
    }
    
    for _, prefix in ipairs(searchPaths) do
        local fullPath = prefix .. className
        local status, module = pcall(require, fullPath)
        if status then
            -- Usually components return a table with the class field, e.g. { PhysicCMP = ... }
            -- or just the class table. logic depends on file structure.
            -- Based on existing files: e.g. PhysicCMP.lua returns Key "PhysicCMP".
            if module[className] then
                return module[className]
            end
            -- If the module IS the class (less common in this project structure but possible)
            if module.new then return module end
        end
    end
    
    MUtils.Error(LOG_MODULE, "Could not resolve component class: " .. className)
    return nil
end

-- T005: Instantiate component with dependency injection
function LevelManager:_instantiateComponent(compData, systems)
    local Class = self:_resolveComponent(compData.type)
    if not Class then return nil end
    
    local instance = nil
    
    -- Factory Logic
    if compData.type == 'PhysicCMP' then
        -- Dependency Injection: PhysicWorld
        local world = systems['PhysicSys']:getWorld()
        
        -- Need to convert pure data shape to Shape object
        -- We assume the PhysicCMP.Shape class is available via require('Component.PhysicCMP').Shape
        -- Or we can resolve it from the class module if it exposes it?
        -- Current PhysicCMP.lua usage: require('Component.PhysicCMP').Shape
        
        local ShapeClass = require('Component.PhysicCMP').Shape
        local shapeData = compData.args.shape
        local shapeObj = nil
        
        if shapeData.type == 'Rectangle' then
            shapeObj = ShapeClass.static.Rectangle(
                shapeData.width, shapeData.height, 
                shapeData.x or 0, shapeData.y or 0, 
                shapeData.angle or 0, shapeData.density
            )
        elseif shapeData.type == 'Circle' then
            shapeObj = ShapeClass.static.Circle(
                shapeData.radius, 
                shapeData.x or 0, shapeData.y or 0, 
                shapeData.density
            )
        end
        
        -- Construct opts for PhysicCMP
        local opts = {
            bodyType = compData.args.bodyType,
            shape = shapeObj,
            fixture = compData.args.fixture,
            fixedRotation = compData.args.fixedRotation
        }
        
        instance = Class:new(world, opts)
    else
        -- Generic instantiation
        -- compData.args is expected to be a list of arguments for :new(...)
        -- but if :new takes named args or specific order, this is fragile.
        -- Most components here take specific args or opts table.
        -- Let's assume compData.args can be passed unpack(args) if list, or as single if table?
        -- "TransformCMP":new() takes nothing.
        -- "DebugColorBlockCMP":new(color, w, h)
        
        if compData.args then
             if type(compData.args) == 'table' and #compData.args > 0 then
                instance = Class:new(unpack(compData.args))
             else
                instance = Class:new(compData.args)
             end
        else
            instance = Class:new()
        end
    end
    
    return instance
end

-- T006: Inject properties
function LevelManager:_applyComponentProperties(component, props, actions)
    if not props then return end
    
    for key, value in pairs(props) do
        if key == 'callback' and actions then
            -- T012: Bind Logic Actions (Preliminary hook)
            local func = actions[value]
            if func then
                if component.setCallback then
                    component:setCallback(func)
                else
                     MUtils.Error(LOG_MODULE, "Component " .. component.ComponentTypeName .. " has no setCallback method.")
                end
            else
                 MUtils.Error(LOG_MODULE, "Action function not found: " .. value)
            end
        else
            -- Setter injection: worldPosition -> setWorldPosition
            local setterName = 'set' .. key:gsub("^%l", string.upper)
            if component[setterName] then
                if type(value) == 'table' and #value > 0 then
                    component[setterName](component, unpack(value))
                else
                    component[setterName](component, value)
                end
            else
                -- Try direct assignment? No, safer to log warning
                -- MUtils.Warning(LOG_MODULE, "No setter " .. setterName .. " on " .. component.ComponentTypeName)
            end
        end
    end
end

-- T007: Build Entity Recursively
function LevelManager:_buildEntity(entityData, parent, systems, actions)
    local MOD_Entity = require('Entity')
    local entity = MOD_Entity:new(entityData.name)
    
    -- Fix: Enable and set visible by default for loaded entities
    if entityData.enable ~= nil then
        entity:setEnable(entityData.enable)
    else
        entity:setEnable(true)
    end

    if entityData.visible ~= nil then
        entity:setVisible(entityData.visible)
    else
        entity:setVisible(true)
    end
    
    if entityData.tag then
        -- entity:setTag(entityData.tag) -- if setTag exists
    end

    if entityData.rewind then
        entity:setNeedRewind(true)
    end
    
    if entityData.components then
        for _, compData in ipairs(entityData.components) do
            local component = self:_instantiateComponent(compData, systems)
            if component then
                -- Step 1: Bind Component First (Fixes TransformCMP dependency issue)
                entity:boundComponent(component)
                -- Step 2: Apply Properties
                self:_applyComponentProperties(component, compData.properties, actions)
            end
        end
    end
    
    if parent then
        parent:boundChildEntity(entity)
    end
    
    if entityData.children then
        for _, childData in ipairs(entityData.children) do
            self:_buildEntity(childData, entity, systems, actions)
        end
    end
    
    return entity
end

function LevelManager:_loadLevelFromData(dataPath, systems, levelInstance)
    local data = self:_loadDataFile(dataPath)
    if not data then return {} end
    
    local entities = {}
    
    -- Load Action Script (T015)
    local actions = nil
    -- Script/Level/LevelName.lua
    local scriptName = data.name
    local scriptPath = "Level." .. scriptName -- Require uses dots, resolved relative to Script/ via package.path
    local status, scriptModule = pcall(require, scriptPath)
    if status then
        actions = scriptModule
    else
        -- Try file path mapping if require fails (e.g. if scriptName has spaces? unlikely)
        -- MUtils.Log(LOG_MODULE, "No action script found for level: " .. scriptName)
    end
    
    if levelInstance and levelInstance.setActions then
        levelInstance:setActions(actions)
    end
    
    if data.entities then
        for _, entityDesc in ipairs(data.entities) do
             local entity = self:_buildEntity(entityDesc, nil, systems, actions)
             table.insert(entities, entity)
             
             -- Track in level instance for unloading
             if levelInstance and levelInstance.addEntity then
                 levelInstance:addEntity(entity)
             end
        end
    end
    
    return entities
end

function LevelManager:requestLoadLevel(levelIdentifier)
    local status, levelModule = pcall(require, levelIdentifier)
    if status then
        self._nextLevelModule = levelModule
        return levelModule
    end
    
    -- T008: Support loading from Resources/Level data
    -- Name resolution: "Levels.Level1" -> "Level1"
    local levelName = levelIdentifier:match("[^%.]+$") or levelIdentifier
    local dataPath = "Resources/Level/" .. levelName .. ".lua"
    
    if love.filesystem.getInfo(dataPath) then
        -- Create a Virtual Level Class (Closure-based or Table-based)
        local VirtualLevel = {}
        VirtualLevel.__index = VirtualLevel
        VirtualLevel.static = {}
        VirtualLevel.static.name = levelName
        
        function VirtualLevel.static.getName() return levelName end
        
        function VirtualLevel:new()
             local instance = setmetatable({}, VirtualLevel)
             instance._levelEntities = {}
             return instance
        end
        
        function VirtualLevel:addEntity(entity)
            table.insert(self._levelEntities, entity)
        end

        function VirtualLevel:getName()
            return VirtualLevel.static.name
        end
        
        function VirtualLevel:setActions(actions) 
            self._actions = actions 
        end
        
        function VirtualLevel:load(systems)
            return LevelManager.static.getInstance():_loadLevelFromData(dataPath, systems, self)
        end
        
        function VirtualLevel:unload(entities, systems)
            -- Copy from BaseLevel unload logic
             local entitiesToRemove = {}
            for _, entity in ipairs(self._levelEntities) do
                entity:onLeaveLevel()
                entitiesToRemove[entity] = true
            end
            
            for i = #entities, 1, -1 do
                local entity = entities[i]
                if entitiesToRemove[entity] then
                    table.remove(entities, i)
                end
            end
            self._levelEntities = {}
        end
        
        self._nextLevelModule = VirtualLevel
        return VirtualLevel
    end

    MUtils.Error(LOG_MODULE, "Error loading level module: " .. levelIdentifier)
    MUtils.Error(LOG_MODULE, levelModule) -- print require error
    return nil
end

function LevelManager:requestUnloadLevelsExceptCurrent()
    if self._previousLevel ~= nil then
        table.insert(self._unloadLevelsList, self._previousLevel)
        self._previousLevel = nil
    end
end

---@param levelObj Level
---@param entities table
---@param systems table
function LevelManager:loadLevel(levelObj, entities, systems)
    if levelObj == nil then
        MUtils.Error(LOG_MODULE, "Cannot load nil level!")
        return
    end

    -- Atomic Transition: Unload Current effectively immediately
    if self._currentLevel ~= nil then
        MUtils.Log(LOG_MODULE, "Unloading current level: " .. self._currentLevel:getName())
        self._currentLevel:unload(entities, systems)
        MessageCenter.static.getInstance():broadcastImmediate(self, Event_LevelUnloaded, { level = self._currentLevel })
    end
    
    -- Clean up any other pending unloads to ensure clean slate
    if #self._unloadLevelsList > 0 then
        for i = 1, #self._unloadLevelsList do
            local levelToUnload = self._unloadLevelsList[i]
            if levelToUnload ~= self._currentLevel then -- Avoid double unload if it was in list
                 MUtils.Log(LOG_MODULE, "Unloading queued level: " .. levelToUnload:getName())
                 levelToUnload:unload(entities, systems)
                 MessageCenter.static.getInstance():broadcastImmediate(self, Event_LevelUnloaded, { level = levelToUnload })
            end
        end
        self._unloadLevelsList = {}
    end

    self._previousLevel = self._currentLevel

    MUtils.Log(LOG_MODULE, "Loading level: " .. levelObj.static.getName())
    self._currentLevel = levelObj:new()
    local level_entities = self._currentLevel:load(systems)
    for i = 1, #level_entities do
        table.insert(entities, level_entities[i])
    end

    MessageCenter.static.getInstance():broadcastImmediate(self, Event_LevelLoaded, { level = self._currentLevel })

end

function LevelManager:tick(entities, systems)
    if #self._pendingSpawnEntities > 0 then
        if entities then
            for i = 1, #self._pendingSpawnEntities do
                local entity = self._pendingSpawnEntities[i]
                table.insert(entities, entity)
                if self._currentLevel and self._currentLevel.addEntity then
                    self._currentLevel:addEntity(entity)
                end
            end
        end
        self._pendingSpawnEntities = {}
    end

    if #self._unloadLevelsList > 0 then
        for i = 1, #self._unloadLevelsList do
            local levelToUnload = self._unloadLevelsList[i]
            MUtils.Log(LOG_MODULE, "Unloading level: " .. levelToUnload:getName())
            levelToUnload:unload(entities, systems)
            MessageCenter.static.getInstance():broadcastImmediate(self, Event_LevelUnloaded, { level = levelToUnload })
        end
        self._unloadLevelsList = {}
    end
    if self._nextLevelModule ~= nil then
        MUtils.Log(LOG_MODULE, "try to load level module.")
        self:loadLevel(self._nextLevelModule, entities, systems)
        self._nextLevelModule = nil
    end
end

return {
    LevelManager = LevelManager,
    Event_LevelLoaded = Event_LevelLoaded,
    Event_LevelUnloaded = Event_LevelUnloaded
}
