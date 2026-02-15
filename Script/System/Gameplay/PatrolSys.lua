local MOD_BaseSystem = require('BaseSystem').BaseSystem
local PatrolType = require('Component.Gameplay.PatrolCMP').PatrolType
local PatrolCMP = require('Component.Gameplay.PatrolCMP').PatrolCMP
local MovementCMP = require('Component.MovementCMP').MovementCMP
local TransformCMP = require('Component.TransformCMP').TransformCMP

--- 巡逻系统，处理各种巡逻行为
---@class PatrolSys : BaseSystem
local PatrolSys = setmetatable({}, MOD_BaseSystem)
PatrolSys.__index = PatrolSys
PatrolSys.SystemTypeName = "PatrolSys"

function PatrolSys:new(world)
    local instance = setmetatable(MOD_BaseSystem.new(self, PatrolSys.SystemTypeName, world), self)
    local ComponentRequirementDesc = require('BaseSystem').ComponentRequirementDesc
    instance:addComponentRequirement(PatrolCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))
    instance:addComponentRequirement(MovementCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))
    instance:addComponentRequirement(TransformCMP.ComponentTypeID, ComponentRequirementDesc:new(true, true))
    instance:initView()
    return instance
end

--- 每帧调用，更新所有收集到的实体的巡逻行为
---@param deltaTime number 距离上一帧的时间间隔，单位秒
---@return nil
function PatrolSys:tick(deltaTime)
    MOD_BaseSystem.tick(self, deltaTime)
    
    local view = self:getComponentsView()
    local patrols = view._components[PatrolCMP.ComponentTypeID]
    local movements = view._components[MovementCMP.ComponentTypeID]
    local transforms = view._components[TransformCMP.ComponentTypeID]
    
    if not patrols or not movements or not transforms then return end
    local count = view._count
    
    for i = 1, count do
        ---@type PatrolCMP
        local patrolCmp = patrols[i]
        ---@type MovementCMP
        local movementCmp = movements[i]
        ---@type TransformCMP
        local transformCmp = transforms[i]

        if patrolCmp.enabled then
            self:executePatrol(patrolCmp, movementCmp, transformCmp, deltaTime)
        end
    end
end

--- 执行具体的巡逻行为
---@param patrolCmp PatrolCMP
---@param movementCmp MovementCMP
---@param transformCmp TransformCMP
---@param deltaTime number
function PatrolSys:executePatrol(patrolCmp, movementCmp, transformCmp, deltaTime)
    local patrolType = patrolCmp.patrolType
    local params = patrolCmp.params

    if patrolType == PatrolType.CIRCULAR_POINT then
        self:circularPointPatrol(patrolCmp, movementCmp, transformCmp, deltaTime)
    elseif patrolType == PatrolType.CIRCULAR_ENTITY then
        self:circularEntityPatrol(patrolCmp, movementCmp, transformCmp, deltaTime)
    elseif patrolType == PatrolType.LINEAR_PATROL_POINTS then
        self:linearPatrolPoints(patrolCmp, movementCmp, transformCmp, deltaTime)
    elseif patrolType == PatrolType.LINEAR_PATROL_ENTITIES then
        self:linearPatrolEntities(patrolCmp, movementCmp, transformCmp, deltaTime)
    else
        assert(false, "Unknown patrolType: " .. tostring(patrolType))
    end
end

--- 围绕固定点环绕巡逻
---@param patrolCmp PatrolCMP
---@param movementCmp MovementCMP
---@param transformCmp TransformCMP
---@param deltaTime number
function PatrolSys:circularPointPatrol(patrolCmp, movementCmp, transformCmp, deltaTime)
    local params = patrolCmp.params

    local centerX = params.centerX
    local centerY = params.centerY
    local radius = params.radius
    local angularSpeed = params.angularSpeed

    -- 获取当前位置
    local currentX, currentY = transformCmp:getTranslate_const()

    -- 计算到中心的向量
    local dx = currentX - centerX
    local dy = currentY - centerY
    local distance = math.sqrt(dx*dx + dy*dy)

    -- 如果距离为0，避免除零
    if distance == 0 then
        distance = 0.001
        dx, dy = 1, 0
    end

    -- 计算当前角度
    local currentAngle = math.atan2(dy, dx)

    -- 计算切线速度（垂直于半径的方向）
    local tangentAngle = currentAngle + math.pi/2 -- 顺时针旋转
    local speed = angularSpeed * radius
    local vx = speed * math.cos(tangentAngle)
    local vy = speed * math.sin(tangentAngle)

    -- 如果不在正确半径上，添加径向速度调整
    local radialAdjustment = 0
    if math.abs(distance - radius) > 1 then
        radialAdjustment = (radius - distance) * 2 -- 简单的比例调整
        vx = vx + radialAdjustment * math.cos(currentAngle)
        vy = vy + radialAdjustment * math.sin(currentAngle)
    end

    movementCmp:setVelocity(vx, vy)
end

--- 围绕实体环绕巡逻
---@param patrolCmp PatrolCMP
---@param movementCmp MovementCMP
---@param transformCmp TransformCMP
---@param deltaTime number
function PatrolSys:circularEntityPatrol(patrolCmp, movementCmp, transformCmp, deltaTime)
    local params = patrolCmp.params
    local targetEntity = params.targetEntity

    if not targetEntity then return end

    -- 获取目标实体的位置
    ---@type TransformCMP
    local targetTransform = targetEntity:getComponent('TransformCMP')
    if not targetTransform then return end

    -- 获取目标实体的世界空间位置（使用世界空间）
    local centerX, centerY = targetTransform:getWorldPosition_const()
    local radius = params.radius or 50
    local angularSpeed = params.angularSpeed or 1

    -- 获取自身的世界空间位置（使用世界空间）
    local currentX, currentY = transformCmp:getWorldPosition_const()

    -- 计算到中心的向量
    local dx = currentX - centerX
    local dy = currentY - centerY
    local distance = math.sqrt(dx*dx + dy*dy)

    -- 如果距离为0，避免除零
    if distance == 0 then
        distance = 0.001
        dx, dy = 1, 0
    end

    -- 计算当前角度
    local currentAngle = math.atan2(dy, dx)

    -- 计算切线速度
    local tangentAngle = currentAngle + math.pi/2
    local speed = angularSpeed * radius
    local vx = speed * math.cos(tangentAngle)
    local vy = speed * math.sin(tangentAngle)

    -- 如果不在正确半径上，添加径向速度调整（仍然在世界空间下）
    local radialAdjustment = 0
    if math.abs(distance - radius) > 1 then
        radialAdjustment = (radius - distance) * 2
        vx = vx + radialAdjustment * math.cos(currentAngle)
        vy = vy + radialAdjustment * math.sin(currentAngle)
    end

    -- 确保 MovementCMP 的作用模式为 world，这样 EntityMovementSys 会把计算出来的世界空间速度
    -- 转换为对 TransformCMP 的世界位移（通过 pending world translate）
    if type(movementCmp.setAffectMode) == 'function' then
        movementCmp:setAffectMode('world')
    end
    movementCmp:setVelocity(vx, vy)
end

--- 在两点之间直线往返巡逻
---@param patrolCmp PatrolCMP
---@param movementCmp MovementCMP
---@param transformCmp TransformCMP
---@param deltaTime number
function PatrolSys:linearPatrolPoints(patrolCmp, movementCmp, transformCmp, deltaTime)
    local params = patrolCmp.params
    local state = patrolCmp:getState()

    local point1X = params.point1X
    local point1Y = params.point1Y
    local point2X = params.point2X
    local point2Y = params.point2Y
    local speed = params.speed

    -- 初始化状态
    if state.targetPoint == nil then
        state.targetPoint = 2 -- 初始目标是point2
    end

    local currentX, currentY = transformCmp:getTranslate_const()
    local targetX, targetY

    if state.targetPoint == 1 then
        targetX, targetY = point1X, point1Y
    else
        targetX, targetY = point2X, point2Y
    end

    -- 计算到目标的向量
    local dx = targetX - currentX
    local dy = targetY - currentY
    local distance = math.sqrt(dx*dx + dy*dy)

    if distance < 5 then -- 到达目标点附近
        -- 切换目标点
        state.targetPoint = (state.targetPoint == 1) and 2 or 1
        patrolCmp:setState(state)
        movementCmp:setVelocity(0, 0) -- 停止
    else
        -- 计算单位向量并设置速度
        local unitX = dx / distance
        local unitY = dy / distance
        local vx = unitX * speed
        local vy = unitY * speed
        movementCmp:setVelocity(vx, vy)
    end
end

--- 在两个实体之间直线往返巡逻
---@param patrolCmp PatrolCMP
---@param movementCmp MovementCMP
---@param transformCmp TransformCMP
---@param deltaTime number
function PatrolSys:linearPatrolEntities(patrolCmp, movementCmp, transformCmp, deltaTime)
    local params = patrolCmp.params
    local entity1 = params.entity1
    local entity2 = params.entity2
    local speed = params.speed or 50

    if not entity1 or not entity2 then return end
    ---@type TransformCMP
    local transform1 = entity1:getComponent('TransformCMP')
    ---@type TransformCMP
    local transform2 = entity2:getComponent('TransformCMP')
    if not transform1 or not transform2 then return end

    local point1X, point1Y = transform1:getTranslate_const()
    local point2X, point2Y = transform2:getTranslate_const()

    -- 使用linearPatrolPoints的逻辑，但传入动态点
    local tempParams = {
        point1X = point1X,
        point1Y = point1Y,
        point2X = point2X,
        point2Y = point2Y,
        speed = speed
    }

    -- 临时修改params来复用逻辑
    local originalParams = patrolCmp.params
    patrolCmp.params = tempParams
    self:linearPatrolPoints(patrolCmp, movementCmp, transformCmp, deltaTime)
    patrolCmp.params = originalParams
end

return {
    PatrolSys = PatrolSys
}
