
local MOD_BaseSystem = require('BaseSystem').BaseSystem
local PhysicCMP = require('Component.PhysicCMP').PhysicCMP
local TransformCMP = require('Component.TransformCMP').TransformCMP

---@class PhysicSys : BaseSystem
local PhysicSys = setmetatable({}, MOD_BaseSystem)
PhysicSys.__index = PhysicSys
PhysicSys.SystemTypeName = "PhysicSys"

function PhysicSys:new(world)
    local instance = setmetatable(MOD_BaseSystem.new(self, PhysicSys.SystemTypeName, world), self)
    local ComponentRequirementDesc = require('BaseSystem').ComponentRequirementDesc
    instance:addComponentRequirement(PhysicCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))
    instance:addComponentRequirement(TransformCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))
    instance._physicsWorld = love.physics.newWorld(0, 9.8, false)  -- 创建一个物理世界，重力向下，单位为米/秒²
    
    -- [Phase 3] Use World event bus
    -- instance._collisionEvents = {}

    instance._physicsWorld:setCallbacks(
        function(a, b, coll)
            -- 碰撞开始回调
            local userDataA = a:getUserData()
            local userDataB = b:getUserData()
            -- 假如fixture没有UserData，尝试获取Body的UserData
            if not userDataA then userDataA = a:getBody():getUserData() end
            if not userDataB then userDataB = b:getBody():getUserData() end

            if userDataA and userDataB then
                -- [Phase 3] Push to World
                instance._world:recordCollisionEvent({a = userDataA, b = userDataB, type = 'begin', contact = coll})
            end
        end,
        function(a, b, coll)
            -- 碰撞结束回调
            local userDataA = a:getUserData()
            local userDataB = b:getUserData()
             if not userDataA then userDataA = a:getBody():getUserData() end
            if not userDataB then userDataB = b:getBody():getUserData() end

            if userDataA and userDataB then
                -- [Phase 3] Push to World
                instance._world:recordCollisionEvent({a = userDataA, b = userDataB, type = 'end', contact = coll})
            end
        end,
        nil,
        nil
    )
    instance:initView()
    return instance

end

--- 获取当前帧的碰撞事件列表 (Deprecated, use World instead)
function PhysicSys:getCollisionEvents()
    -- return self._collisionEvents
    return self._world:getCollisionEvents()
end

function PhysicSys:getPhysicsWorld()
    return self._physicsWorld
end

function PhysicSys:tick(deltaTime)
    MOD_BaseSystem.tick(self, deltaTime)

    -- self._collisionEvents = {} -- Handled by World:clean()
    
    local view = self:getComponentsView()
    -- CHANGE: Use ComponentTypeName instead of ComponentTypeID
    local physics = view._components[PhysicCMP.ComponentTypeName]
    local transforms = view._components[TransformCMP.ComponentTypeName]
    
    if not physics or not transforms then return end
    local count = view._count
    
    local TimeManager = require('TimeManager').TimeManager.static.getInstance()
    local scale = TimeManager:getTimeScale()
    local physicsDt = deltaTime * scale
    local worldGravityX, worldGravityY = self._physicsWorld:getGravity()

    local exceptionComponents = {} 
    
    -- 先对所有的物理组件进行必要的更新
    for i = 1, count do
        ---@type PhysicCMP
        local physicCmp = physics[i]
        ---@type TransformCMP
        local transformCmp = transforms[i]
        
        -- 从世界变换矩阵中分解出位置、旋转应用到物理组件上
        if physicCmp._body and transformCmp then
            -- Note: Setting physics body position from transform forces physics to snap.
            -- This contradicts later logic where physics updates transform.
            -- Usually: Physics drives Transform (for dynamic).
            -- Transform drives Physics (for kinematic/static or initialization).
            -- If we do BOTH in every frame, who wins?
            -- Code order:
            -- 1. Transform -> Physics
            -- 2. Physics World Step
            -- 3. Physics -> Transform
            -- This implies Transform set elsewhere (e.g. movement, animation) overrides Physics previous state,
            -- then Physics simulates, then result is written back.
            -- This seems to support "Kinematic" or "Controller" based movement overriding physics,
            -- but for Dynamic bodies, this resets velocity/position effecitvely?
            
            -- Wait, if TransformUpdateSys ran before, it calculated WorldTransform.
            -- Only update physics body if we need to sync?
            -- Original code did exactly this. Preserving logic.
            
            local x, y = transformCmp:getWorldPosition_const()
            local rotation = transformCmp:getWorldRotate_const()
            physicCmp:setBodyPosition(x, y)
            physicCmp:setBodyRotate(rotation)
        end
        
        -- [TimeManager Support] 
        -- Avoid division by zero when scale is near 0. If scale is 0, physics is paused anyway.
        if math.abs(scale - 1.0) > 0.001 and scale > 0.0001 then
            local entity = physicCmp:getEntity_const() -- Use const variant if available or just getEntity
            if entity and entity:isTimeScaleException_const() then
                local vx, vy = physicCmp:getLinearVelocity_const()
                local angularVel = physicCmp:getAngularVelocity_const()
                
                -- 速度补偿：放大速度
                physicCmp:setLinearVelocity(vx / scale, vy / scale)
                physicCmp:setAngularVelocity(angularVel / scale)

                -- 重力补偿：施加额外力
                -- F_add = m * g * (1/scale - 1)
                -- 只有当body受重力影响且是Dynamic类型时才施加
                if physicCmp:getBodyType_const() == 'dynamic' and physicCmp:getGravityScale_const() > 0 then
                    local mass = physicCmp:getMass_const()
                    local factor = (1.0 / scale) - 1.0
                    physicCmp:applyForce(worldGravityX * mass * factor, worldGravityY * mass * factor)
                end

                table.insert(exceptionComponents, physicCmp)
            end
        end
    end

    self._physicsWorld:update(physicsDt)

    -- [TimeManager Support] 还原速度
    if #exceptionComponents > 0 then
        for _, physicCmp in ipairs(exceptionComponents) do
            local vx, vy = physicCmp:getLinearVelocity_const()
            local angularVel = physicCmp:getAngularVelocity_const()
            physicCmp:setLinearVelocity(vx * scale, vy * scale)
            physicCmp:setAngularVelocity(angularVel * scale)
        end
    end

    -- 然后将物理组件的位置和旋转反馈回变换组件
    for i = 1, count do
        ---@type PhysicCMP
        local physicCmp = physics[i]
        ---@type TransformCMP
        local transformCmp = transforms[i]
        if physicCmp._body and transformCmp then
            -- assert(physicCmp:getBody():isAwake())
            local x, y = physicCmp:getBodyPosition_const()
            local rotation = physicCmp:getBodyRotate_const()
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

function PhysicVisualizeSys:new(world)
    local instance = setmetatable(MOD_BaseSystem.new(self, PhysicVisualizeSys.SystemTypeName, world), self)
    local ComponentRequirementDesc = require('BaseSystem').ComponentRequirementDesc
    instance:addComponentRequirement(PhysicCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))
    instance:initView()
    return instance
end


function PhysicVisualizeSys:draw()
    local MOD_PhysicShape = require('Component.PhysicCMP').Shape
    MOD_BaseSystem.draw(self)
    
    local view = self:getComponentsView()
    local physics = view._components[PhysicCMP.ComponentTypeID]
    if not physics then return end
    local count = view._count
    
    local old_colors_r, old_colors_g, old_colors_b, old_colors_a = love.graphics.getColor()

    --- 内部函数：根据是否为静态物体更新颜色
    local _local_update_color = function(is_static)
        if is_static then
            love.graphics.setColor(0, 0, 255, 100)  -- 半透明绿色
        else
            love.graphics.setColor(255, 0, 0, 100)  -- 半透明红色
        end
    end

    for i = 1, count do
        ---@type PhysicCMP
        local physicCmp = physics[i]
        if physicCmp:getShape_const() and physicCmp:getBody() then
            _local_update_color(physicCmp:isBodyStatic_const())
            local shapeType = physicCmp:getShape_const():getType_const()
            if shapeType == MOD_PhysicShape.static.Type.CIRCLE then
                local x, y = physicCmp:getBodyPosition_const()
                love.graphics.circle("fill"
                    , x, y
                    , 1)
            elseif shapeType == MOD_PhysicShape.static.Type.RECTANGLE then
                ---@type Rectangle
                local rectangleShape = physicCmp:getShape_const()
                local center_x, center_y = physicCmp:getBodyPosition_const()
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
