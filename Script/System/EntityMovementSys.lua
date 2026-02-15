
local MOD_BaseSystem = require('BaseSystem').BaseSystem
local MovementCMP = require('Component.MovementCMP').MovementCMP
local TransformCMP = require('Component.TransformCMP').TransformCMP
local TimeManager = require('TimeManager').TimeManager

--- 控制实体移动的系统
--- 这个系统会收集所有拥有MovementCMP以及TransformCMP组件的实体
--- 然后根据MovementCMP组件内的速度属性，更新TransformCMP组件内的位置属性
---@class EntityMovementSys : BaseSystem
local EntityMovementSys = setmetatable({}, MOD_BaseSystem)
EntityMovementSys.__index = EntityMovementSys
EntityMovementSys.SystemTypeName = "EntityMovementSys"

function EntityMovementSys:new(world)
    local instance = setmetatable(MOD_BaseSystem.new(self, EntityMovementSys.SystemTypeName, world), self)
    local ComponentRequirementDesc = require('BaseSystem').ComponentRequirementDesc
    instance:addComponentRequirement(MovementCMP.ComponentTypeID, ComponentRequirementDesc:new(true, true))
    instance:addComponentRequirement(TransformCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))
    instance:initView()
    return instance
end

--- 每帧调用，更新所有收集到的实体的位置
---@param deltaTime number 距离上一帧的时间间隔，单位秒
---@return nil
function EntityMovementSys:tick(deltaTime)
    MOD_BaseSystem.tick(self, deltaTime)
    
    local view = self:getComponentsView()
    local movements = view._components[MovementCMP.ComponentTypeID]
    local transforms = view._components[TransformCMP.ComponentTypeID]
    
    if not movements or not transforms then return end
    
    local count = view._count
    local tmInstance = TimeManager.static.getInstance()
    
    for i = 1, count do
        ---@type MovementCMP
        local movementCmp = movements[i]
        ---@type TransformCMP
        local transformCmp = transforms[i]
        
        local dt = tmInstance:getDeltaTime(deltaTime, movementCmp:getEntity_const())
        local vecX, vecY = movementCmp:getVelocity_const()
        local dx, dy = vecX * dt, vecY * dt
        local affect = nil
        if type(movementCmp.getAffectMode) == 'function' then
            affect = movementCmp:getAffectMode_const()
        end
        if affect == nil or affect == "local" then
            -- apply to local transform
            transformCmp:translate(dx, dy)
        else
            transformCmp:translateWorldPosition(dx, dy)
        end
    end
end

return {
    EntityMovementSys = EntityMovementSys,
}

