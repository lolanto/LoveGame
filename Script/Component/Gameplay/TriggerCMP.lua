local MOD_BaseComponent = require('BaseComponent').BaseComponent

---@class TriggerCMP : BaseComponent
---@field _callback function|nil 触发回调函数
local TriggerCMP = setmetatable({}, MOD_BaseComponent)
TriggerCMP.__index = TriggerCMP

TriggerCMP.ComponentTypeName = "TriggerCMP"
TriggerCMP.ComponentTypeID = MOD_BaseComponent.RegisterType(TriggerCMP.ComponentTypeName)

--- 构造Trigger组件
--- 触发器的形状和位置由Entity绑定的 PhysicCMP (物理组件) 决定。
--- 必须确保同一Entity上绑定了 PhysicCMP 并且正确设置了 Fixture/Sensor。
function TriggerCMP:new()
    local instance = setmetatable(MOD_BaseComponent.new(self, TriggerCMP.ComponentTypeName), self)
    instance._callback = nil
    return instance
end

--- 设置触发器的回调函数
--- 当物理系统检测到碰撞/重叠，并且两个物体都需要触发Trigger时调用
--- @param callback function 签名: function(selfEntity, otherEntity)
function TriggerCMP:setCallback(callback)
    self._callback = callback
end

--- 获取回调函数
--- @return function|nil
function TriggerCMP:getCallback()
    return self._callback
end

--- 手动触发回调 (由 TriggerSys 调用)
--- @param otherEntity Entity
function TriggerCMP:executeCallback(otherEntity)
    if self._callback then
        self._callback(self:getEntity(), otherEntity)
    end
end

return {
    TriggerCMP = TriggerCMP
}
