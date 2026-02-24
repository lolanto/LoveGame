--[[
    用来调试绘制的组件，会在屏幕绘制一个彩色圆圈表示实体位置
--]]

local MOD_BaseComponent = require('BaseComponent').BaseComponent
local MOD_DrawableCMP = require('Component.DrawableCMP').DrawableCMP

---@class DebugColorCircleCMP : DrawableCMP
---@field _color table 颜色，格式为{r,g,b,a}
---@field _radius number 半径
local DebugColorCircleCMP = setmetatable({}, MOD_DrawableCMP)
DebugColorCircleCMP.__index = DebugColorCircleCMP
DebugColorCircleCMP.ComponentTypeName = "DebugColorCircleCMP"
DebugColorCircleCMP.ComponentTypeID = MOD_BaseComponent.RegisterType(DebugColorCircleCMP.ComponentTypeName)

---cst
---@param color table 颜色，格式为{r,g,b,a}
---@param radius number 半径
---@return DebugColorCircleCMP
function DebugColorCircleCMP:new(color, radius)
    local instance = setmetatable(MOD_DrawableCMP.new(self, DebugColorCircleCMP.ComponentTypeName), self)
    instance._color = color or {1, 0, 0, 1}
    instance._radius = radius or 10
    return instance
end

function DebugColorCircleCMP:setColor(color)
    self._color = color
end

--- 当前组件发起绘制
--- @param transform love.Transform 用来指导绘制位置的变换矩阵,目前设计是世界空间下的位置
--- @return nil
function DebugColorCircleCMP:draw(transform)
    love.graphics.setColor(self._color)
    -- 从transform中提取平移和缩放信息
    local mat1_1, mat1_2, mat1_3, mat1_4
        , mat2_1, mat2_2, mat2_3, mat2_4
        , mat3_1, mat3_2, mat3_3, mat3_4
        , mat4_1, mat4_2, mat4_3, mat4_4 = transform:getMatrix()
    local translateX = mat1_4
    local translateY = mat2_4
    local scaleX = math.sqrt(mat1_1 * mat1_1 + mat2_1 * mat2_1)
    local scaleY = math.sqrt(mat1_2 * mat1_2 + mat2_2 * mat2_2)
    local actualRadiusX = self._radius * scaleX
    local actualRadiusY = self._radius * scaleY
    love.graphics.ellipse("fill"
        , translateX
        , translateY
        , actualRadiusX
        , actualRadiusY)
    love.graphics.setColor({1,1,1,1})
end

return {
    DebugColorCircleCMP = DebugColorCircleCMP
}