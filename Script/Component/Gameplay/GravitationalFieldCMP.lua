
local MOD_BaseComponent = require('BaseComponent').BaseComponent

---@class GravitationalFieldCMP : BaseComponent
---@field _radius number 影响半径
---@field _forceStrength number 引力强度
---@field _minRadius number 最小半径(防止引力过大)
local GravitationalFieldCMP = setmetatable({}, MOD_BaseComponent)
GravitationalFieldCMP.__index = GravitationalFieldCMP
GravitationalFieldCMP.ComponentTypeName = "GravitationalFieldCMP"
GravitationalFieldCMP.ComponentTypeID = MOD_BaseComponent.RegisterType(GravitationalFieldCMP.ComponentTypeName)

---@param radius number 影响半径
---@param forceStrength number 引力强度 (默认为1000)
---@param minRadius number 最小半径 (默认为0.5)
function GravitationalFieldCMP:new(radius, forceStrength, minRadius)
    local instance = setmetatable(MOD_BaseComponent.new(self, GravitationalFieldCMP.ComponentTypeName), self)
    instance._radius = radius or 5.0
    instance._forceStrength = forceStrength or 1000.0
    instance._minRadius = minRadius or 0.5
    instance._ignoreEntities = {}
    return instance
end

function GravitationalFieldCMP:getRadius_const()
    return self._radius
end

function GravitationalFieldCMP:getForceStrength_const()
    return self._forceStrength
end

function GravitationalFieldCMP:getMinRadius_const()
    return self._minRadius
end

function GravitationalFieldCMP:addIgnoreEntity(entity)
    if entity then
        self._ignoreEntities[entity] = true
    end
end

function GravitationalFieldCMP:isIgnored_const(entity)
    return self._ignoreEntities[entity] == true
end

function GravitationalFieldCMP:getRewindState_const()
    -- Typically static config, but saving in case of dynamic modification
    return {
        radius = self._radius,
        force = self._forceStrength,
        minRadius = self._minRadius
    }
end

function GravitationalFieldCMP:restoreRewindState(state)
    if not state then return end
    self._radius = state.radius or self._radius
    self._forceStrength = state.force or self._forceStrength
    self._minRadius = state.minRadius or self._minRadius
end

return {
    GravitationalFieldCMP = GravitationalFieldCMP
}
