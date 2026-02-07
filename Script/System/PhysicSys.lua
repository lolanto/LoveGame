
local MOD_BaseSystem = require('BaseSystem').BaseSystem

---@class PhysicSys : BaseSystem
local PhysicSys = setmetatable({}, MOD_BaseSystem)
PhysicSys.__index = PhysicSys
PhysicSys.SystemTypeName = "PhysicSys"

function PhysicSys:new()
    local instance = setmetatable(MOD_BaseSystem.new(self, PhysicSys.SystemTypeName), self)
    local ComponentRequirementDesc = require('BaseSystem').ComponentRequirementDesc
    instance:addComponentRequirement(require('Component.PhysicCMP').PhysicCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))
    instance:addComponentRequirement(require('Component.TransformCMP').TransformCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))
    instance._world = love.physics.newWorld(0, 9.8, false)  -- 创建一个物理世界，重力向下，单位为米/秒²
    
    instance._collisionEvents = {}

    instance._world:setCallbacks(
        function(a, b, coll)
            -- 碰撞开始回调
            local userDataA = a:getUserData()
            local userDataB = b:getUserData()
            -- 假如fixture没有UserData，尝试获取Body的UserData
            if not userDataA then userDataA = a:getBody():getUserData() end
            if not userDataB then userDataB = b:getBody():getUserData() end

            if userDataA and userDataB then
                table.insert(instance._collisionEvents, {a = userDataA, b = userDataB, type = 'begin', contact = coll})
            end
        end,
        function(a, b, coll)
            -- 碰撞结束回调
            local userDataA = a:getUserData()
            local userDataB = b:getUserData()
             if not userDataA then userDataA = a:getBody():getUserData() end
            if not userDataB then userDataB = b:getBody():getUserData() end

            if userDataA and userDataB then
                table.insert(instance._collisionEvents, {a = userDataA, b = userDataB, type = 'end', contact = coll})
            end
        end,
        nil,
        nil
    )
    return instance

end

--- 获取当前帧的碰撞事件列表
function PhysicSys:getCollisionEvents()
    return self._collisionEvents
end

function PhysicSys:getWorld()
    return self._world
end

function PhysicSys:tick(deltaTime)
    MOD_BaseSystem.tick(self, deltaTime)

    self._collisionEvents = {}
    
    -- 先对所有的物理组件进行必要的更新
    for i = 1, #self._collectedComponents['PhysicCMP'] do
        ---@type PhysicCMP
        local physicCmp = self._collectedComponents['PhysicCMP'][i]
        ---@type TransformCMP
        local transformCmp = self._collectedComponents['TransformCMP'][i]
        -- 从世界变换矩阵中分解出位置、旋转应用到物理组件上
        if physicCmp._body and transformCmp then
            local x, y = transformCmp:getWorldPosition_const()
            local rotation = transformCmp:getWorldRotate_const()
            physicCmp:setBodyPosition(x, y)
            physicCmp:setBodyRotate(rotation)
            -- TODO：Transform身上的Scale应该怎么反映到物理组件上呢？
        end
    end

    -- 更新物理世界
    local TimeManager = require('TimeManager').TimeManager.static.getInstance()
    local scale = TimeManager:getTimeScale()
    local physicsDt = deltaTime * scale
    local worldGravityX, worldGravityY = self._world:getGravity()

    -- [TimeManager Support] 
    -- 针对不受时间缩放影响的例外实体，我们需要进行补偿：
    -- 1. 速度补偿：为了在较短的PhysicsDT内移动相同的逻辑距离，物理速度需要放大 (1/scale)
    -- 2. 重力补偿：为了在较短的PhysicsDT内获得相同的重力加速度效果，需要施加额外的重力 F = m * g * (1/scale - 1)
    local exceptionBodies = {} 
    if math.abs(scale - 1.0) > 0.001 then
        for i = 1, #self._collectedComponents['PhysicCMP'] do
            local physicCmp = self._collectedComponents['PhysicCMP'][i]
            local entity = physicCmp:getEntity()
            if physicCmp._body and entity:isTimeScaleException_const() then
                local body = physicCmp._body
                local vx, vy = body:getLinearVelocity()
                local angularVel = body:getAngularVelocity()
                
                -- 速度补偿：放大速度
                body:setLinearVelocity(vx / scale, vy / scale)
                body:setAngularVelocity(angularVel / scale)

                -- 重力补偿：施加额外力
                -- F_add = m * g * (1/scale - 1)
                -- 只有当body受重力影响且是Dynamic类型时才施加
                if body:getType() == 'dynamic' and body:getGravityScale() > 0 then
                    local mass = body:getMass()
                    local factor = (1.0 / scale) - 1.0
                    body:applyForce(worldGravityX * mass * factor, worldGravityY * mass * factor)
                end

                table.insert(exceptionBodies, body)
            end
        end
    end

    self._world:update(physicsDt)

    -- [TimeManager Support] 还原速度
    -- 物理模拟结束后，物体现在的物理速度是放大的，我们需要将其还原回逻辑速度
    -- v_logical = v_phys * scale
    if #exceptionBodies > 0 then
        for _, body in ipairs(exceptionBodies) do
            local vx, vy = body:getLinearVelocity()
            local angularVel = body:getAngularVelocity()
            body:setLinearVelocity(vx * scale, vy * scale)
            body:setAngularVelocity(angularVel * scale)
        end
    end

    -- 然后将物理组件的位置和旋转反馈回变换组件
    for i = 1, #self._collectedComponents['PhysicCMP'] do
        ---@type PhysicCMP
        local physicCmp = self._collectedComponents['PhysicCMP'][i]
        ---@type TransformCMP
        local transformCmp = self._collectedComponents['TransformCMP'][i]
        if physicCmp._body and transformCmp then
            -- assert(physicCmp:getBody():isAwake())
            local x, y = physicCmp:getBodyPosition()
            local rotation = physicCmp:getBodyRotate()
            transformCmp:setWorldPosition(x, y)
            transformCmp:setWorldRotate(rotation)
        end
    end
    
end


----------------------------------------------------------------

--- 用来调试物理碰撞的可视化系统
---@class PhysicVisualizeSys : BaseSystem
local PhysicVisualizeSys = setmetatable({}, MOD_BaseSystem)
PhysicVisualizeSys.__index = PhysicVisualizeSys
PhysicVisualizeSys.SystemTypeName = "PhysicVisualizeSys"

function PhysicVisualizeSys:new()
    local instance = setmetatable(MOD_BaseSystem.new(self, PhysicVisualizeSys.SystemTypeName), self)
    local ComponentRequirementDesc = require('BaseSystem').ComponentRequirementDesc
    instance:addComponentRequirement(require('Component.PhysicCMP').PhysicCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))
    return instance
end


function PhysicVisualizeSys:draw()
    local MOD_PhysicShape = require('Component.PhysicCMP').Shape
    MOD_BaseSystem.draw(self)
    local old_colors_r, old_colors_g, old_colors_b, old_colors_a = love.graphics.getColor()

    --- 内部函数：根据是否为静态物体更新颜色
    local _local_update_color = function(is_static)
        if is_static then
            love.graphics.setColor(0, 0, 255, 100)  -- 半透明绿色
        else
            love.graphics.setColor(255, 0, 0, 100)  -- 半透明红色
        end
    end

    for i = 1, #self._collectedComponents['PhysicCMP'] do
        ---@type PhysicCMP
        local physicCmp = self._collectedComponents['PhysicCMP'][i]
        if physicCmp:getShape() and physicCmp:getBody() then
            _local_update_color(physicCmp:isBodyStatic_const())
            local shapeType = physicCmp:getShape():getType_const()
            if shapeType == MOD_PhysicShape.static.Type.CIRCLE then
                local x, y = physicCmp:getBodyPosition()
                love.graphics.circle("fill"
                    , x, y
                    , 1)
            elseif shapeType == MOD_PhysicShape.static.Type.RECTANGLE then
                ---@type Rectangle
                local rectangleShape = physicCmp:getShape()
                local center_x, center_y = physicCmp:getBodyPosition()
                local top_left_x = center_x - rectangleShape:getWidth_const() / 2
                local top_left_y = center_y - rectangleShape:getHeight_const() / 2
                love.graphics.rectangle("fill"
                    , top_left_x, top_left_y
                    , rectangleShape:getWidth_const()
                    , rectangleShape:getHeight_const())
            end
        end
    end
    love.graphics.setColor(old_colors_r, old_colors_g, old_colors_b, old_colors_a)  -- 恢复为白色不透明
end

return {
    PhysicSys = PhysicSys,
    PhysicVisualizeSys = PhysicVisualizeSys,
}
