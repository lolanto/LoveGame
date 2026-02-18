
local MOD_BaseComponent = require('BaseComponent').BaseComponent

---@class LifeTimeCMP : BaseComponent
---@field _maxDuration number 最大持续时间
---@field _elapsedTime number 已经持续的时间
local LifeTimeCMP = setmetatable({}, MOD_BaseComponent)
LifeTimeCMP.__index = LifeTimeCMP
LifeTimeCMP.ComponentTypeName = "LifeTimeCMP"
LifeTimeCMP.ComponentTypeID = MOD_BaseComponent.RegisterType(LifeTimeCMP.ComponentTypeName)

---@param duration number 持续时间
function LifeTimeCMP:new(duration)
    local instance = setmetatable(MOD_BaseComponent.new(self, LifeTimeCMP.ComponentTypeName), self)
    instance._maxDuration = duration or 10.0
    instance._elapsedTime = 0.0
    return instance
end

function LifeTimeCMP:getMaxDuration_const()
    return self._maxDuration
end

function LifeTimeCMP:getElapsedTime_const()
    return self._elapsedTime
end

function LifeTimeCMP:addElapsedTime(dt)
    self._elapsedTime = self._elapsedTime + dt
end

function LifeTimeCMP:isExpired_const()
    return self._elapsedTime >= self._maxDuration
end

function LifeTimeCMP:getRewindState_const()
    return {
        elapsedTime = self._elapsedTime
    }
end

function LifeTimeCMP:restoreRewindState(state)
    if state and state.elapsedTime then
        self._elapsedTime = state.elapsedTime
    end
end

return {
    LifeTimeCMP = LifeTimeCMP
}
