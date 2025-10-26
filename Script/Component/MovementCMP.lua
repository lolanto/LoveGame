
local MOD_BaseComponent = require('BaseComponent').BaseComponent

--- 控制移动的组件，有这个组件理论上才能移动。它记录一系列移动相关的属性

---@class MovementCMP : BaseComponent
---@field _velocityX number 速度X分量，单位m/s
---@field _velocityY number 速度Y分量，单位m/s
local MovementCMP = setmetatable({}, MOD_BaseComponent)
MovementCMP.__index = MovementCMP
MovementCMP.ComponentTypeName = "MovementCMP"
MovementCMP.ComponentTypeID = MOD_BaseComponent.RegisterType(MovementCMP.ComponentTypeName)


function MovementCMP:new()
    local instance = setmetatable(MOD_BaseComponent.new(self, MovementCMP.ComponentTypeName), self)
    instance._velocityX = 0.0
    instance._velocityY = 0.0
    -- affect mode: "local" (default) means apply to TransformCMP local properties
    -- "world" means the movement will be cached and later applied to world transform
    instance._affectMode = "local"
    -- NOTE: pending world-space translation is stored on the TransformCMP of the entity.
    return instance
end

function MovementCMP:setVelocity(velocityX, velocityY)
    self._velocityX = velocityX
    self._velocityY = velocityY
end


--- 设置这个 MovementCMP 的作用目标（"local" 或 "world"）
---@param mode string
function MovementCMP:setAffectMode(mode)
    if mode ~= "local" and mode ~= "world" then
        error("Invalid affect mode: " .. tostring(mode))
    end
    self._affectMode = mode
end

function MovementCMP:getAffectMode_const()
    return self._affectMode
end


function MovementCMP:getVelocity_const()
    return self._velocityX, self._velocityY
end

return {
    MovementCMP = MovementCMP
}

