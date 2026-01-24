
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
    self._world:update(deltaTime)

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
