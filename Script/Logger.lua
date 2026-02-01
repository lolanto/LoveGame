local Logger = {}
local Config = require('Config').Config.Logger

-- Define Log Levels
Logger.Level = {
    DEBUG = 1,
    INFO = 2,
    WARNING = 3,
    ERROR = 4
}

-- String to Level mapping for Config
local StringToLevel = {
    ["DEBUG"] = Logger.Level.DEBUG,
    ["INFO"] = Logger.Level.INFO,
    ["WARNING"] = Logger.Level.WARNING,
    ["ERROR"] = Logger.Level.ERROR
}

Logger.LevelName = {
    [1] = "DEBUG",
    [2] = "INFO ", -- Padding for alignment
    [3] = "WARN ",
    [4] = "ERROR"
}

Logger.RegisteredModules = {}

-- Store the current log file name
local logDir = "Saved/Log"
local currentLogFile = logDir .. "/GameLog.log"


--- Parse Config Levels
local function getConfigLevel(levelStr, default)
    if not levelStr then return default end
    return StringToLevel[string.upper(levelStr)] or default
end

local globalConsoleLevel = getConfigLevel(Config.GlobalConsoleLevel, Logger.Level.INFO)
local globalFileLevel = getConfigLevel(Config.GlobalFileLevel, Logger.Level.INFO)

-- Helper: Check if file exists using standard IO
local function fileExists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

--- Initialize the Logger: Handle file rotation
function Logger.Init()
    -- Enable OS commands to create directory
    local pathSeparator = package.config:sub(1,1)
    local isWindows = (pathSeparator == "\\")
    local osCmd = ""

    if isWindows then
        -- Windows: Create dir if not exists (quietly)
        local winPath = logDir:gsub("/", "\\")
        osCmd = 'if not exist "' .. winPath .. '" mkdir "' .. winPath .. '"'
    else
        -- Unix/Mac
        osCmd = 'mkdir -p "' .. logDir .. '"'
    end
    os.execute(osCmd)


    if fileExists(currentLogFile) then
        local timestamp = os.date("%Y%m%d_%H%M%S")
        local backupName = logDir .. "/GameLog_bak_" .. timestamp .. ".log"
        os.rename(currentLogFile, backupName)
    end
    
    -- Start fresh log file
    local f = io.open(currentLogFile, "w")
    if f then
        f:write(string.format("--- Game Log Started at %s ---\n", os.date("%Y-%m-%d %H:%M:%S")))
        f:close()
        
        -- Try to get absolute path for display helpfulness
        -- love.filesystem.getSource() usually points to the folder containing main.lua
        local projectDir = love.filesystem.getSource()
        print("Logger Initialized. Log file located at: " .. projectDir .. "/" .. currentLogFile)
    else
        print("Logger Error: Failed to create log file at " .. currentLogFile)
    end

    Logger.Log("Logger", "Log system initialized.")
end

--- Register a module (Optional, but good for validation if enforced)
function Logger.RegisterModule(moduleName, consoleLevelStr, fileLevelStr)
    Logger.RegisteredModules[moduleName] = {
        consoleLevel = getConfigLevel(consoleLevelStr, globalConsoleLevel),
        fileLevel = getConfigLevel(fileLevelStr, globalFileLevel)
    }
    
    -- Check config for overrides
    if Config.Modules[moduleName] then
        if Config.Modules[moduleName].ConsoleLevel then
            Logger.RegisteredModules[moduleName].consoleLevel = getConfigLevel(Config.Modules[moduleName].ConsoleLevel)
        end
        if Config.Modules[moduleName].FileLevel then
            Logger.RegisteredModules[moduleName].fileLevel = getConfigLevel(Config.Modules[moduleName].FileLevel)
        end
    end
end

--- Get effective levels for a module
local function getModuleLevels(moduleName)
    local config = Logger.RegisteredModules[moduleName]
    if config then
        return config.consoleLevel, config.fileLevel
    end
    
    -- Check if it is in Config but not manually registered via code
    if Config.Modules[moduleName] then
         local sysConf = Config.Modules[moduleName]
         return getConfigLevel(sysConf.ConsoleLevel, globalConsoleLevel), 
                getConfigLevel(sysConf.FileLevel, globalFileLevel)
    end

    -- Default
    return globalConsoleLevel, globalFileLevel
end


--- Core Log Function
---@param moduleName string
---@param level number
---@param message string
function Logger.Write(moduleName, level, message)
    local consoleLvl, fileLvl = getModuleLevels(moduleName)
    local levelName = Logger.LevelName[level] or "UNKNOWN"
    local timestamp = os.date("%H:%M:%S")
    
    -- Format: [Time][Level][Module] Message
    local logString = string.format("[%s][%s][%s] %s", timestamp, levelName, moduleName, message)

    -- Console Output
    if Config.EnableConsole and level >= consoleLvl then
        print(logString)
    end

    -- File Output
    if Config.EnableFile and level >= fileLvl then
        local f = io.open(currentLogFile, "a")
        if f then
            f:write(logString .. "\n")
            f:close()
        end
    end
end

-- Helpers matching the request
function Logger.Log(moduleName, message)
    Logger.Write(moduleName, Logger.Level.INFO, message)
end

function Logger.Warning(moduleName, message)
    Logger.Write(moduleName, Logger.Level.WARNING, message)
end

function Logger.Error(moduleName, message)
    Logger.Write(moduleName, Logger.Level.ERROR, message)
end

function Logger.Debug(moduleName, message)
    Logger.Write(moduleName, Logger.Level.DEBUG, message)
end

return Logger
