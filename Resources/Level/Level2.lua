return {
    name = "Level2",
    entities = {
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
        -- Wall Right (Has Trigger)
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
                {
                    type = "TriggerCMP",
                    properties = { callback = "onRightWallTrigger" }
                },
                { type = "TransformCMP", properties = { worldPosition = {7.5, 0} } }
            },
            children = {
               {
                     name = "debug",
                     components = {
                        { type = "DebugColorBlockCMP", args = { {128,0,0,255}, 1, 10 }, properties = { layer = -1 } },
                        { type = "TransformCMP" },
                        { type = "MovementCMP" }
                     }
                }
            }
        }
    }
}