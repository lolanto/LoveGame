
local Config = {
    IS_DEBUG = true,
    
    -- Gameplay Configuration
    BlackHole = {
        -- TriggerKey = 't', -- Moved to Client.Input
        Radius = 5.0,
        ForceStrength = 400.0,
        MinRadius = 0.5,
        Duration = 10.0,
        SpawnOffset = {x = 0, y = -3},
        SpawnCooldown = 1.0,
        DebugColor = {0, 0, 0, 0.8}
    },
    
    Client = {
        Input = {
            Interact = {
                BlackHole = {
                    Activation = 'o',
                    Cancel = 'escape',
                    Movement = {
                        Up = 'w',
                        Down = 's',
                        Left = 'a',
                        Right = 'd'
                    }
                }
            }
        }
    },

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
