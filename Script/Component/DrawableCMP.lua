--[[
    这个组件是所有能够被绘制的组件的基类
    DrawableCMP.lua
--]]

local MOD_BaseComponent = require('BaseComponent').BaseComponent

---@class DrawableCMP : BaseComponent
---@field _maxBounding any 组件的最大包围盒, 参与决定是否需要渲染
---@field _layer number 绘制层级，数值越大越靠前
local DrawableCMP = setmetatable({}, MOD_BaseComponent)
DrawableCMP.__index = DrawableCMP
DrawableCMP.ComponentTypeName = "DrawableCMP"
DrawableCMP.ComponentTypeID = MOD_BaseComponent.RegisterType(DrawableCMP.ComponentTypeName)

function DrawableCMP:new()
    local instance = setmetatable(MOD_BaseComponent.new(self, DrawableCMP.ComponentTypeName), self)
    instance._maxBounding = nil
    instance._layer = 0 -- 绘制层级，数值越大越靠前
    return instance
end

--- 当前组件发起绘制
---@param transform love.Transform 用来指导绘制位置的变换矩阵,目前设计是世界空间下的位置
---@return nil
function DrawableCMP:draw(transform)
    -- 这个函数需要子类重写
    assert(false, "DrawableCMP:draw() need to be overridden in subclass")
end

--- 返回绘制组件的最大包围盒，这个包围盒之后会参与决定被挂接实体最后是否需要渲染
--- @return any 组件的最大包围盒
function DrawableCMP:getMaxBounding()
    return self._maxBounding
end

function DrawableCMP:getLayer()
    return self._layer
end

---设置绘制的层级，层级越大越靠前
---@param layer number 层级
function DrawableCMP:setLayer(layer)
    self._layer = layer
end

return {
    DrawableCMP = DrawableCMP
}
