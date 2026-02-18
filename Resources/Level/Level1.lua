return {
    name = "Level1",
    entities = {
        -- phyDebug
        {
            name = "phyDebug",
            rewind = true,
            components = {
                {
                    type = "PhysicCMP",
                    args = {
                        bodyType = "dynamic", -- default
                        shape = { type = "Rectangle", width = 1, height = 1, density = 1 }
                    }
                },
                {
                    type = "TransformCMP",
                    properties = {
                        worldPosition = {0, -10}
                    }
                }
            },
            children = {
                {
                    name = "debug",
                    components = {
                        {
                            type = "DebugColorBlockCMP",
                            args = { {255,0,0,255}, 1, 1 },
                            properties = { layer = -1 }
                        },
                        { type = "TransformCMP" },
                        { type = "MovementCMP" }
                    }
                }
            }
        },
        -- Balls
        {
            name = "ball1",
            rewind = true,
            components = {
                {
                    type = "DebugColorCircleCMP",
                    args = { {255,0,0,255}, 0.5 }
                },
                { type = "TransformCMP", properties = { worldPosition = {-0.5, -5} } },
                { type = "MovementCMP" },
                {
                    type = "PhysicCMP",
                    args = {
                        shape = { type = "Circle", radius = 0.5, density = 1 },
                        fixture = { friction = 0.5, restitution = 0.3 }
                    }
                }
            }
        },
        {
            name = "ball2",
            rewind = true,
            components = {
                {
                    type = "DebugColorCircleCMP",
                    args = { {0,255,0,255}, 0.5 }
                },
                { type = "TransformCMP", properties = { worldPosition = {0, -6.1} } },
                { type = "MovementCMP" },
                {
                    type = "PhysicCMP",
                    args = {
                        shape = { type = "Circle", radius = 0.5, density = 1 },
                        fixture = { friction = 0.5, restitution = 0.3 }
                    }
                }
            }
        },
        {
            name = "ball3",
            rewind = true,
            components = {
                {
                    type = "DebugColorCircleCMP",
                    args = { {0,0,255,255}, 0.5 }
                },
                { type = "TransformCMP", properties = { worldPosition = {0.5, -5} } },
                { type = "MovementCMP" },
                {
                    type = "PhysicCMP",
                    args = {
                        shape = { type = "Circle", radius = 0.5, density = 1 },
                        fixture = { friction = 0.5, restitution = 0.3 }
                    }
                }
            }
        },
        -- Ground
        {
            name = "ground",
            components = {
                 {
                    type = "PhysicCMP",
                    args = {
                        bodyType = "static",
                        shape = { type = "Rectangle", width = 15, height = 1 },
                        fixture = { friction = 0.8, restitution = 0.0 }
                    }
                },
                { type = "TransformCMP", properties = { worldPosition = {0, 5} } }
            },
            children = {
                {
                    name = "debug",
                    components = {
                        {
                            type = "DebugColorBlockCMP",
                            args = { {0,0,255,255}, 15, 1 },
                            properties = { layer = -1 }
                        },
                        { type = "TransformCMP" },
                        { type = "MovementCMP" }
                    }
                }
            }
        },
        -- Wall Left (Has Trigger)
        {
            name = "wallLeft",
            components = {
                {
                    type = "PhysicCMP",
                    args = {
                        bodyType = "static",
                        shape = { type = "Rectangle", width = 1, height = 10 },
                        fixture = { friction = 0.8, restitution = 0.0 }
                    }
                },
                {
                    type = "TriggerCMP",
                    properties = { callback = "onLeftWallTrigger" }
                },
                { type = "TransformCMP", properties = { worldPosition = {-7.5, 0} } }
            },
            children = {
                {
                     name = "debug",
                     components = {
                        { type = "DebugColorBlockCMP", args = { {0,255,0,255}, 1, 10 }, properties = { layer = -1 } },
                        { type = "TransformCMP" },
                        { type = "MovementCMP" }
                     }
                }
            }
        },
        -- Wall Right
        {
            name = "wallRight",
            components = {
                {
                    type = "PhysicCMP",
                    args = {
                        bodyType = "static",
                        shape = { type = "Rectangle", width = 1, height = 10 },
                        fixture = { friction = 0.8, restitution = 0.0 }
                    }
                },
                { type = "TransformCMP", properties = { worldPosition = {7.5, 0} } }
            },
            children = {
               {
                     name = "debug",
                     components = {
                        { type = "DebugColorBlockCMP", args = { {0,255,0,255}, 1, 10 }, properties = { layer = -1 } },
                        { type = "TransformCMP" },
                        { type = "MovementCMP" }
                     }
                }
            }
        }
    }
}