--- Level2关卡定义
local BaseLevel = require('Levels.BaseLevel')
local Level = setmetatable({}, {__index = BaseLevel})
Level.__index = Level
Level.static = {}
Level.static.name = "Level2"
Level.static.getName = function() return Level.static.name end

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

    local LevelManager = require('LevelManager')
    LevelManager.static.getInstance():requestUnloadLevelsExceptCurrent()

    return self:getEntities()
end

return Level