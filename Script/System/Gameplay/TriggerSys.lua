local MOD_BaseSystem = require('BaseSystem').BaseSystem

---@class TriggerSys : BaseSystem
local TriggerSys = setmetatable({}, MOD_BaseSystem)
TriggerSys.__index = TriggerSys
TriggerSys.SystemTypeName = "TriggerSys"

function TriggerSys:new(world)
    local instance = setmetatable(MOD_BaseSystem.new(self, TriggerSys.SystemTypeName, world), self)
    local ComponentRequirementDesc = require('BaseSystem').ComponentRequirementDesc
    local TriggerCMP = require('Component.Gameplay.TriggerCMP').TriggerCMP
    
    -- 我们注册 TriggerCMP 需求，虽然核心逻辑是响应 Collision 事件，但这能让系统感知 Trigger 组件的存在。
    instance:addComponentRequirement(TriggerCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))
    instance:initView()
    
    -- instance._physicSys = nil -- Deprecated
    return instance
end

function TriggerSys:tick(deltaTime)
    MOD_BaseSystem.tick(self, deltaTime)

    local events = self._world:getCollisionEvents()
    if not events then return end

    for _, event in ipairs(events) do
        -- 这里我们只处理 'begin' 事件作为触发时刻
        -- 如果需要在这里处理持续重叠或者结束重叠，可以根据 event.type 判断
        if event.type == 'begin' then
            self:handleCollision(event.a, event.b)
        end
    end
end

--- 处理单次碰撞事件
--- @param entityA Entity
--- @param entityB Entity
function TriggerSys:handleCollision(entityA, entityB)
    -- 必须确保这两个对象都是 Entity 类型 (PhysicSystem 中传入的 UserData)
    -- 安全起见，检查是否有 getComponent 方法
    if not entityA.getComponent or not entityB.getComponent then
        return
    end

    -- 尝试获取 TriggerCMP
    local triggerA = entityA:getComponent('TriggerCMP')
    local triggerB = entityB:getComponent('TriggerCMP')

    -- 如果 entityA 有触发器，触发它的回调，传入 entityB 作为交互对象
    if triggerA then
        triggerA:executeCallback(entityB)
    end

    -- 如果 entityB 有触发器，触发它的回调，传入 entityA 作为交互对象
    if triggerB then
        triggerB:executeCallback(entityA)
    end
end

return {
    TriggerSys = TriggerSys
}
