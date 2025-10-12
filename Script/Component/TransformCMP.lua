
local MOD_BaseComponent = require('BaseComponent')

---@class TransformCMP : BaseComponent
---@field _posX number
---@field _posY number
---@field _rotate number
---@field _scaleX number
---@field _scaleY number
---@field _isDirty boolean
---@field _transform nil|love.Transform
local TransformCMP = setmetatable({}, {__index = MOD_BaseComponent})
TransformCMP.__index = TransformCMP
TransformCMP.ComponentTypeName = "TransformCMP"
TransformCMP.ComponentTypeID = MOD_BaseComponent.RegisterType(TransformCMP.ComponentTypeName)


function TransformCMP:new()
    local instance = setmetatable(MOD_BaseComponent.new(self, TransformCMP.ComponentTypeName), self)
    instance._posX = 0
    instance._posY = 0
    instance._rotate = 0
    instance._scaleX = 1
    instance._scaleY = 1
    instance._isDirty = true
    instance._transform = nil
    return instance
end

---获取位移情况
---@return number,number 返回x和y的位移
function TransformCMP:getTranslate()
    return self._posX, self._posY
end

---获取缩放情况
---@return number,number 返回x和y轴的缩放程度
function TransformCMP:getScale()
    return self._scaleX, self._scaleY
end

---获取旋转情况
---@return number 返回旋转的角度
function TransformCMP:getRotate()
    return self._rotate
end

---设置位移大小
---@param x number x轴向位移
---@param y number y轴向位移
function TransformCMP:setTranslate(x, y)
    assert(x ~= nil and y ~= nil)
    self._posX = x
    self._posY = y
    self._isDirty = true
end

---设置位移偏移大小
---@param dx number x轴向位移偏移
---@param dy number y轴向位移偏移
function TransformCMP:addTranslate(dx, dy)
    assert(dx ~= nil and dy ~= nil)
    self._posX = self._posX + dx
    self._posY = self._posY + dy
    self._isDirty = true
end

---设置缩放大小
---@param x number x轴向的缩放大小
---@param y number y轴向的缩放大小
function TransformCMP:setScale(x, y)
    assert(x ~= nil and y ~= nil)
    self._scaleX = x
    self._scaleY = y
    self._isDirty = true
end

---设置旋转角度
---@param r number 旋转角度，正值为顺时针
function TransformCMP:setRotate(r)
    assert(r ~= next)
    self._rotate = r
    self._isDirty = true
end

---返回变换矩阵情况，假如中间参数有变更会申请一个变换
---@return love.Transform 返回变换矩阵
function TransformCMP:getTransform()
    if self._isDirty then
        self._transform = love.math.newTransform(self._posX, self._posY, self._rotate, self._scaleX, self._scaleY, 0, 0)
        self._isDirty = false
    end
    return self._transform
end

return TransformCMP

