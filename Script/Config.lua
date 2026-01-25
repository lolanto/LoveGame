
local Config = {
    IS_DEBUG = true,
    
    -- Logger Configuration
    Logger = {
        EnableConsole = true,
        EnableFile = true,
        GlobalConsoleLevel = "DEBUG", -- Options: DEBUG, INFO, WARNING, ERROR
        GlobalFileLevel = "DEBUG",
        
        -- Registered Modules and their specific overrides (optional)
        -- If a module is not listed here but used, it defaults to Global Levels
        Modules = {
            -- Example:
            -- ["System"] = { ConsoleLevel = "INFO", FileLevel = "DEBUG" },
            -- ["Gameplay"] = { ConsoleLevel = "WARNING" } -- Inherits FileLevel from Global
        }
    }
}

return {
    Config = Config,
}
