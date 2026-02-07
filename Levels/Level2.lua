--- Level2关卡定义
local BaseLevel = require('Levels.BaseLevel')
local Level = setmetatable({}, {__index = BaseLevel})
Level.__index = Level
Level.static = {}
Level.static.name = "Level2"
Level.static.getName = function() return Level.static.name end

--- 属于这个关卡的Gameplay函数声明
local func_rightWallTrigger = nil

function Level:new()
    local instance = BaseLevel:new(Level.static.name)
    setmetatable(instance, self)
    return instance
end

function Level:load(systems)
    local MOD_Entity = require('Entity')

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
    wallRight:boundComponent(require('Component.Gameplay.TriggerCMP').TriggerCMP:new())
    wallRight:getComponent('TriggerCMP'):setCallback(func_rightWallTrigger)
    self:addEntity(wallRight)

    local wallRight_deb = MOD_Entity:new('debug')
    wallRight_deb:boundComponent(require('Component.DrawableComponents.DebugColorBlockCMP').DebugColorBlockCMP:new({128, 0, 0, 255}, 1, 10))
    wallRight_deb:getComponent('DebugColorBlockCMP'):setLayer(-1) --
    wallRight_deb:boundComponent(require('Component.TransformCMP').TransformCMP:new())
    wallRight_deb:boundComponent(require('Component.MovementCMP').MovementCMP:new())
    self:addEntity(wallRight_deb)
    wallRight:boundChildEntity(wallRight_deb)

    local LevelManager = require('LevelManager').LevelManager
    LevelManager.static.getInstance():requestUnloadLevelsExceptCurrent()

    return self:getEntities()
end

function func_rightWallTrigger(selfEntity, otherEntity)
    if otherEntity:getName_const() == 'player' then
        require('LevelManager').LevelManager.static.getInstance():requestLoadLevel('Levels.Level1')
    end
end

return Level