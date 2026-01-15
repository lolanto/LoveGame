--[[

    -- 示例：创建直线往返巡逻的实体
    local entityPatrolLinear = MOD_Entity:new('patrol_linear')
    entityPatrolLinear:boundComponent(require('Component.DrawableComponents.DebugColorBlockCMP').DebugColorBlockCMP:new({0,255,255,255}, 1, 1))
    entityPatrolLinear:boundComponent(require('Component.TransformCMP').TransformCMP:new())
    entityPatrolLinear:getComponent('TransformCMP'):setPosition(10, 10)
    entityPatrolLinear:boundComponent(require('Component.MovementCMP').MovementCMP:new())
    local PatrolTypeParam_LinearPatrolPoints = require('Component.Gameplay.PatrolCMP').PatrolTypeParam_LinearPatrolPoints
    entityPatrolLinear:boundComponent(require('Component.Gameplay.PatrolCMP').PatrolCMP:new(PatrolType.LINEAR_PATROL_POINTS, PatrolTypeParam_LinearPatrolPoints:new(10, 10, 10, 10, 50)))


    -- 示例：创建环绕固定点巡逻的实体
    local entityPatrolCircular = MOD_Entity:new('patrol_circular')
    entityPatrolCircular:boundComponent(require('Component.DrawableComponents.DebugColorBlockCMP').DebugColorBlockCMP:new({255,255,0,255}, 1, 1))
    entityPatrolCircular:boundComponent(require('Component.TransformCMP').TransformCMP:new())
    entityPatrolCircular:getComponent('TransformCMP'):setPosition(2, 1.5) -- 初始位置
    entityPatrolCircular:boundComponent(require('Component.MovementCMP').MovementCMP:new())
    local PatrolType = require('Component.Gameplay.PatrolCMP').PatrolType
    entityPatrolCircular:boundComponent(require('Component.Gameplay.PatrolCMP').PatrolCMP:new(PatrolType.CIRCULAR_ENTITY
        , require('Component.Gameplay.PatrolCMP').PatrolTypeParam_CircularEntity:new(entity, 1, 2)))

--]]


local MOD_BaseComponent = require('BaseComponent').BaseComponent

--- 巡逻类型枚举
local PatrolType = {
    CIRCULAR_POINT = 0,
    CIRCULAR_ENTITY = 1,
    LINEAR_PATROL_POINTS = 2,
    LINEAR_PATROL_ENTITIES = 3
}

local PatrolTypeParam_CircularPoint = setmetatable({}, {})
PatrolTypeParam_CircularPoint.__index = PatrolTypeParam_CircularPoint
function PatrolTypeParam_CircularPoint:new(centerX, centerY, radius, angularSpeed)
    local instance = setmetatable({}, PatrolTypeParam_CircularPoint)
    instance.centerX = centerX
    instance.centerY = centerY
    instance.radius = radius
    instance.angularSpeed = angularSpeed
    return instance
end

local PatrolTypeParam_CircularEntity = setmetatable({}, {})
PatrolTypeParam_CircularEntity.__index = PatrolTypeParam_CircularEntity
function PatrolTypeParam_CircularEntity:new(targetEntity, radius, angularSpeed)
    local instance = setmetatable({}, PatrolTypeParam_CircularEntity)
    instance.targetEntity = targetEntity
    instance.radius = radius
    instance.angularSpeed = angularSpeed
    return instance
end

local PatrolTypeParam_LinearPatrolPoints = setmetatable({}, {})
PatrolTypeParam_LinearPatrolPoints.__index = PatrolTypeParam_LinearPatrolPoints
function PatrolTypeParam_LinearPatrolPoints:new(point1X, point1Y, point2X, point2Y, speed)
    local instance = setmetatable({}, PatrolTypeParam_LinearPatrolPoints)
    instance.point1X = point1X
    instance.point1Y = point1Y
    instance.point2X = point2X
    instance.point2Y = point2Y
    instance.speed = speed
    return instance
end

local PatrolTypeParam_LinearPatrolEntities = setmetatable({}, {})
PatrolTypeParam_LinearPatrolEntities.__index = PatrolTypeParam_LinearPatrolEntities
function PatrolTypeParam_LinearPatrolEntities:new(entity1, entity2, speed)
    local instance = setmetatable({}, PatrolTypeParam_LinearPatrolEntities)
    instance.entity1 = entity1
    instance.entity2 = entity2
    instance.speed = speed
    return instance
end

--- 巡逻组件，定义实体的巡逻行为
---@class PatrolCMP : BaseComponent
---@field patrolType number 巡逻类型 (使用PatrolType枚举)
---@field params table 巡逻参数，根据patrolType不同
---@field enabled boolean 是否启用巡逻
---@field state table 内部状态，用于跟踪巡逻进度
local PatrolCMP = setmetatable({}, MOD_BaseComponent)
PatrolCMP.__index = PatrolCMP
PatrolCMP.ComponentTypeName = "PatrolCMP"
PatrolCMP.ComponentTypeID = MOD_BaseComponent.RegisterType(PatrolCMP.ComponentTypeName)

---@param patrolType number
---@param params table
function PatrolCMP:new(patrolType, params)
    -- 验证patrolType是否有效
    local validTypes = {}
    for k, v in pairs(PatrolType) do
        validTypes[v] = true
    end
    assert(validTypes[patrolType], "Invalid patrolType: " .. tostring(patrolType))
    
    local instance = setmetatable(MOD_BaseComponent.new(self, PatrolCMP.ComponentTypeName), self)
    instance.patrolType = patrolType
    instance.params = params or {}
    instance.enabled = true
    instance.state = {} -- 初始化状态表
    
    -- 验证params结构
    self:validateParams(patrolType, params)
    
    return instance
end

--- 验证params结构
---@param patrolType number
---@param params table
function PatrolCMP:validateParams(patrolType, params)
    if patrolType == PatrolType.CIRCULAR_POINT then
        assert(getmetatable(params) == PatrolTypeParam_CircularPoint,
               "CIRCULAR_POINT requires PatrolTypeParam_CircularPoint instance")
    elseif patrolType == PatrolType.CIRCULAR_ENTITY then
        assert(getmetatable(params) == PatrolTypeParam_CircularEntity,
               "CIRCULAR_ENTITY requires PatrolTypeParam_CircularEntity instance")
    elseif patrolType == PatrolType.LINEAR_PATROL_POINTS then
        assert(getmetatable(params) == PatrolTypeParam_LinearPatrolPoints,
               "LINEAR_PATROL_POINTS requires PatrolTypeParam_LinearPatrolPoints instance")
    elseif patrolType == PatrolType.LINEAR_PATROL_ENTITIES then
        assert(getmetatable(params) == PatrolTypeParam_LinearPatrolEntities,
               "LINEAR_PATROL_ENTITIES requires PatrolTypeParam_LinearPatrolEntities instance")
    end
end

--- 设置巡逻类型和参数
---@param patrolType number
---@param params table
function PatrolCMP:setPatrol(patrolType, params)
    -- 验证patrolType是否有效
    local validTypes = {}
    for k, v in pairs(PatrolType) do
        validTypes[v] = true
    end
    assert(validTypes[patrolType], "Invalid patrolType: " .. tostring(patrolType))
    
    self.patrolType = patrolType
    self.params = params or {}
    self.state = {} -- 重置状态
    
    -- 验证params结构
    self:validateParams(patrolType, params)
end

--- 启用或禁用巡逻
---@param enabled boolean
function PatrolCMP:setEnabled(enabled)
    self.enabled = enabled
end

--- 获取当前状态
---@return table
function PatrolCMP:getState()
    return self.state
end

--- 设置状态
---@param state table
function PatrolCMP:setState(state)
    self.state = state
end

return {
    PatrolCMP = PatrolCMP,
    PatrolType = PatrolType,
    PatrolTypeParam_CircularPoint = PatrolTypeParam_CircularPoint,
    PatrolTypeParam_CircularEntity = PatrolTypeParam_CircularEntity,
    PatrolTypeParam_LinearPatrolPoints = PatrolTypeParam_LinearPatrolPoints,
    PatrolTypeParam_LinearPatrolEntities = PatrolTypeParam_LinearPatrolEntities
}
