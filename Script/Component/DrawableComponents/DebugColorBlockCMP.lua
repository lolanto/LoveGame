--[[
    用来调试绘制的组件，会在屏幕上留下一个色块
--]]

local MOD_BaseComponent = require('BaseComponent').BaseComponent
local MOD_DrawableCMP = require('Component.DrawableCMP').DrawableCMP

---@class DebugColorBlockCMP : DrawableCMP
---@field _color table 颜色，格式为{r,g,b,a}
---@field _width number 宽度
---@field _height number 高度
local DebugColorBlockCMP = setmetatable({}, MOD_DrawableCMP)
DebugColorBlockCMP.__index = DebugColorBlockCMP
DebugColorBlockCMP.ComponentTypeName = "DebugColorBlockCMP"
DebugColorBlockCMP.ComponentTypeID = MOD_BaseComponent.RegisterType(DebugColorBlockCMP.ComponentTypeName)

---cst
---@param color table 颜色，格式为{r,g,b,a}
---@param width number 宽度
---@param height number 高度
function DebugColorBlockCMP:new(color, width, height)
    local instance = setmetatable(MOD_DrawableCMP.new(self, DebugColorBlockCMP.ComponentTypeName), self)
    instance._color = color or {1, 0, 0, 1}
    instance._width = width or 10
    instance._height = height or 10
    return instance
end

--- 当前组件发起绘制
---@param transform love.Transform 用来指导绘制位置的变换矩阵,目前设计是世界空间下的位置
---@return nil
function DebugColorBlockCMP:draw(transform)
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
    local actualTranslateX = translateX - (self._width * scaleX) / 2
    local actualTranslateY = translateY - (self._height * scaleY) / 2
    local actualWidth = self._width * scaleX
    local actualHeight = self._height * scaleY
    love.graphics.rectangle("fill"
        , actualTranslateX
        , actualTranslateY
        , actualWidth
        , actualHeight)
    love.graphics.setColor({1,1,1,1})
end

return {
    DebugColorBlockCMP = DebugColorBlockCMP
}

