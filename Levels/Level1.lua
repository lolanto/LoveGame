--- Level1关卡定义
local BaseLevel = require('Levels.BaseLevel')
local Level = setmetatable({}, {__index = BaseLevel})
Level.__index = Level
Level.static = {}
Level.static.name = "Level1"
Level.static.getName = function() return Level.static.name end

--- 属于这个关卡的Gameplay函数声明
local func_leftWallTrigger = nil

function Level:new()
    local instance = BaseLevel:new(Level.static.name)
    setmetatable(instance, self)
    return instance
end

function Level:load(systems)
    local MOD_Entity = require('Entity')
    
    local entity3 = MOD_Entity:new('phyDebug')
    entity3:boundComponent(require('Component.PhysicCMP').PhysicCMP:new(systems['PhysicSys']:getWorld()
        , {shape = require('Component.PhysicCMP').Shape.static.Rectangle(1, 1, 0, 0, 0, 1)}))
    entity3:boundComponent(require('Component.TransformCMP').TransformCMP:new())
    entity3:getComponent('TransformCMP'):setWorldPosition(0, -10)
    self:addEntity(entity3)
    entity3:setNeedRewind(true)

    local entity3_deb = MOD_Entity:new('debug')
    entity3_deb:boundComponent(require('Component.DrawableComponents.DebugColorBlockCMP').DebugColorBlockCMP:new({255,0,0,255}, 1, 1))
    entity3_deb:getComponent('DebugColorBlockCMP'):setLayer(-1) -- 设置这个组件的绘制层级为-1
    entity3_deb:boundComponent(require('Component.TransformCMP').TransformCMP:new())
    entity3_deb:boundComponent(require('Component.MovementCMP').MovementCMP:new())
    self:addEntity(entity3_deb)
    entity3:boundChildEntity(entity3_deb)

    -- 添加3个下落并堆叠在一起的球体
    local ballColors = {
        {255, 0, 0, 255},   -- Red
        {0, 255, 0, 255},   -- Green
        {0, 0, 255, 255}    -- Blue
    }
    local ballPositions = {
        {-0.5, -5},
        {0, -6.1},
        {0.5, -5}
    }
    for i = 1, 3 do
        local ballEntity = MOD_Entity:new('ball' .. tostring(i))
        ballEntity:boundComponent(require('Component.DrawableComponents.DebugColorCircleCMP').DebugColorCircleCMP:new(ballColors[i], 0.5))
        ballEntity:boundComponent(require('Component.TransformCMP').TransformCMP:new())
        ballEntity:getComponent('TransformCMP'):setWorldPosition(ballPositions[i][1], ballPositions[i][2])
        ballEntity:boundComponent(require('Component.MovementCMP').MovementCMP:new())
        ballEntity:boundComponent(require('Component.PhysicCMP').PhysicCMP:new(
            systems['PhysicSys']:getWorld(),
            {
                shape = require('Component.PhysicCMP').Shape.static.Circle(0.5, 0, 0, 1),
                fixture = { friction = 0.5, restitution = 0.3 }
            }
        ))
        self:addEntity(ballEntity)
        ballEntity:setNeedRewind(true)
    end

    -- 添加场景边界内容
    -- 添加静态地面：宽 30，高 1，放在 y=0
    local ground = MOD_Entity:new('ground')
    ground:boundComponent(require('Component.PhysicCMP').PhysicCMP:new(
        systems['PhysicSys']:getWorld(),
        {
            bodyType = "static",
            shape = require('Component.PhysicCMP').Shape.static.Rectangle(15, 1, 0, 0, 0, 0),
            fixture = { friction = 0.8, restitution = 0.0 }
        }
    ))
    ground:boundComponent(require('Component.TransformCMP').TransformCMP:new())
    ground:getComponent('TransformCMP'):setWorldPosition(0, 5)
    self:addEntity(ground)

    local ground_deb = MOD_Entity:new('debug')
    ground_deb:boundComponent(require('Component.DrawableComponents.DebugColorBlockCMP').DebugColorBlockCMP:new({0, 0, 255, 255}, 15, 1))
    ground_deb:getComponent('DebugColorBlockCMP'):setLayer(-1) -- 设置这个组件的绘制层级为-1
    ground_deb:boundComponent(require('Component.TransformCMP').TransformCMP:new())
    ground_deb:boundComponent(require('Component.MovementCMP').MovementCMP:new())
    self:addEntity(ground_deb)
    ground:boundChildEntity(ground_deb)

    -- 添加两侧墙面
    local wallLeft = MOD_Entity:new('wallLeft')
    wallLeft:boundComponent(require('Component.PhysicCMP').PhysicCMP:new(
        systems['PhysicSys']:getWorld(),
        {
            bodyType = "static",
            shape = require('Component.PhysicCMP').Shape.static.Rectangle(1, 10, 0, 0, 0, 0),
            fixture = { friction = 0.8, restitution = 0.0 }
        }
    ))
    wallLeft:boundComponent(require('Component.Gameplay.TriggerCMP').TriggerCMP:new())
    wallLeft:getComponent('TriggerCMP'):setCallback(func_leftWallTrigger)
    wallLeft:boundComponent(require('Component.TransformCMP').TransformCMP:new())
    wallLeft:getComponent('TransformCMP'):setWorldPosition(-7.5, 0)
    self:addEntity(wallLeft)

    local wallLeft_deb = MOD_Entity:new('debug')
    wallLeft_deb:boundComponent(require('Component.DrawableComponents.DebugColorBlockCMP').DebugColorBlockCMP:new({0, 255, 0, 255}, 1, 10))
    wallLeft_deb:getComponent('DebugColorBlockCMP'):setLayer(-1) --
    wallLeft_deb:boundComponent(require('Component.TransformCMP').TransformCMP:new())
    wallLeft_deb:boundComponent(require('Component.MovementCMP').MovementCMP:new())
    self:addEntity(wallLeft_deb)
    wallLeft:boundChildEntity(wallLeft_deb)

    local wallRight = MOD_Entity:new('wallRight')
    wallRight:boundComponent(require('Component.PhysicCMP').PhysicCMP:new(
        systems['PhysicSys']:getWorld(),
        {
            bodyType = "static",
            shape = require('Component.PhysicCMP').Shape.static.Rectangle(1, 10, 0, 0, 0, 0),
            fixture = { friction = 0.8, restitution = 0.0 }
        }
    ))
    wallRight:boundComponent(require('Component.TransformCMP').TransformCMP:new())
    wallRight:getComponent('TransformCMP'):setWorldPosition(7.5, 0)
    self:addEntity(wallRight)

    local wallRight_deb = MOD_Entity:new('debug')
    wallRight_deb:boundComponent(require('Component.DrawableComponents.DebugColorBlockCMP').DebugColorBlockCMP:new({0, 255, 0, 255}, 1, 10))
    wallRight_deb:getComponent('DebugColorBlockCMP'):setLayer(-1) --
    wallRight_deb:boundComponent(require('Component.TransformCMP').TransformCMP:new())
    wallRight_deb:boundComponent(require('Component.MovementCMP').MovementCMP:new())
    self:addEntity(wallRight_deb)
    wallRight:boundChildEntity(wallRight_deb)

    return self:getEntities()
end

function func_leftWallTrigger(selfEntity, otherEntity)
    if otherEntity:getName_const() == 'player' then
        require('LevelManager').static.getInstance():requestLoadLevel('Levels.Level2')
    end
end

return Level
