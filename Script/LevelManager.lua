local LevelManager = {}

local MUtils = require('MUtils')

local LOG_MODULE = "LevelManager"

function LevelManager.init()
    MUtils.RegisterModule(LOG_MODULE)
end

---@param levelPath string
---@param entities table
---@param systems table
function LevelManager.loadLevel(levelPath, entities, systems)
    local status, levelModule = pcall(require, levelPath)
    if not status then
        MUtils.Error(LOG_MODULE, "Error loading level module: " .. levelPath)
        MUtils.Error(LOG_MODULE, levelModule)
        return
    end

    if levelModule.load then
        MUtils.Log(LOG_MODULE, "Loading level: " .. levelPath)
        levelModule.load(entities, systems)
    else
        MUtils.Error(LOG_MODULE, "Level module " .. levelPath .. " missing 'load' function.")
    end
end

return LevelManager
