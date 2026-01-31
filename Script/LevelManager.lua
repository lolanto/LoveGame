local MUtils = require('MUtils')

local LOG_MODULE = "LevelManager"

--- @class LevelManager
--- @field _currentLevel Level|nil 当前加载的关卡
--- @field _previousLevel Level|nil 上一个关卡
--- @field _nextLevelModule Level|nil 下一个关卡模块（预加载用）
--- @field _unloadLevelsList table 需要卸载的关卡列表
local LevelManager = {}
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
    MUtils.RegisterModule(LOG_MODULE)
    local instance = setmetatable({}, self)
    instance._currentLevel = nil
    instance._previousLevel = nil
    instance._nextLevelModule = nil
    instance._unloadLevelsList = {}
    return instance
end

function LevelManager:getCurrentLevel()
    return self._currentLevel
end

function LevelManager:requireLoadLevel(levelPath)
    local status, levelModule = pcall(require, levelPath)
    if not status then
        MUtils.Error(LOG_MODULE, "Error loading level module: " .. levelPath)
        MUtils.Error(LOG_MODULE, levelModule)
        return nil
    end
    assert(self._nextLevelModule == nil, "只能预加载一个下一个关卡模块！")
    self._nextLevelModule = levelModule
    return levelModule
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

    --- 假如之前的关卡存在，先卸载它
    if self._previousLevel ~= nil then
        MUtils.Log(LOG_MODULE, "Unloading previous level: " .. self._previousLevel:getName())
        table.insert(self._unloadLevelsList, self._previousLevel)
    end
    self._previousLevel = self._currentLevel
    --- Level的加载可能是从别的Level触发的！

    MUtils.Log(LOG_MODULE, "Loading level: " .. levelObj.static.getName())
    self._currentLevel = levelObj:new()
    local level_entities = self._currentLevel:load(systems)
    for i = 1, #level_entities do
        table.insert(entities, level_entities[i])
    end
end

function LevelManager:tick(entities, systems)
    if #self._unloadLevelsList > 0 then
        for i = 1, #self._unloadLevelsList do
            local levelToUnload = self._unloadLevelsList[i]
            MUtils.Log(LOG_MODULE, "Unloading level: " .. levelToUnload:getName())
            levelToUnload:unload(entities, systems)
        end
        self._unloadLevelsList = {}
    end
    if self._nextLevelModule ~= nil then
        MUtils.Log(LOG_MODULE, "try to load level module.")
        self:loadLevel(self._nextLevelModule, entities, systems)
        self._nextLevelModule = nil
    end
end

return LevelManager
