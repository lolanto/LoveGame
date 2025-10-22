--[[
    TransformCMP.lua
    描述: 变换组件，提供位移、旋转、缩放等变换功能

    TODO: 应该提供两个Transform，一个是本地变换，一个是全局变换。其中全局变换需要每帧计算获得
--]]


local MOD_BaseComponent = require('BaseComponent').BaseComponent

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
    -- 世界变换属性
    instance._worldPosX = 0
    instance._worldPosY = 0
    instance._worldRotate = 0
    instance._worldScaleX = 1
    instance._worldScaleY = 1
    instance._worldIsDirty = true
    -- pending world-space translation accumulated externally (e.g. EntityMovementSys)
    instance._pendingWorldDX = 0
    instance._pendingWorldDY = 0
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

---获取世界坐标
---@return number, number 返回世界x和y
function TransformCMP:getWorldPosition()
    return self._worldPosX, self._worldPosY
end

---获取世界缩放
---@return number, number 返回世界缩放x和y
function TransformCMP:getWorldScale()
    return self._worldScaleX, self._worldScaleY
end

---获取世界旋转
---@return number 返回世界旋转角度
function TransformCMP:getWorldRotate()
    return self._worldRotate
end

---设置位移大小
---@param x number x轴向位移
---@param y number y轴向位移
function TransformCMP:setTranslate(x, y)
    assert(x ~= nil and y ~= nil)
    self._posX = x
    self._posY = y
    self._isDirty = true
    self._worldIsDirty = true
end

---设置位移偏移大小
---@param dx number x轴向位移偏移
---@param dy number y轴向位移偏移
function TransformCMP:addTranslate(dx, dy)
    assert(dx ~= nil and dy ~= nil)
    self._posX = self._posX + dx
    self._posY = self._posY + dy
    self._isDirty = true
    self._worldIsDirty = true
end

---设置缩放大小
---@param x number x轴向的缩放大小
---@param y number y轴向的缩放大小
function TransformCMP:setScale(x, y)
    assert(x ~= nil and y ~= nil)
    self._scaleX = x
    self._scaleY = y
    self._isDirty = true
    self._worldIsDirty = true
end

---设置旋转角度
---@param r number 旋转角度，正值为顺时针
function TransformCMP:setRotate(r)
    assert(r ~= next)
    self._rotate = r
    self._isDirty = true
    self._worldIsDirty = true
end

---返回变换矩阵情况，假如中间参数有变更会申请一个变换
---@return love.Transform 返回本地变换矩阵
function TransformCMP:getLocalTransform()
    if self._isDirty then
        self._transform = love.math.newTransform(self._posX, self._posY, self._rotate, self._scaleX, self._scaleY, 0, 0)
        self._isDirty = false
    end
    return self._transform
end

---返回世界变换矩阵
---@return love.Transform 返回世界变换矩阵（由TransformUpdateSystem维护的世界属性生成）
function TransformCMP:getWorldTransform()
    if self._worldIsDirty then
        -- 当世界变换脏时，构建世界变换矩阵
        self._worldTransform = love.math.newTransform(self._worldPosX, self._worldPosY, self._worldRotate, self._worldScaleX, self._worldScaleY, 0, 0)
        self._worldIsDirty = false
    end
    return self._worldTransform
end

---设置世界变换（仅供TransformUpdateSystem调用）
function TransformCMP:_setWorldTransform(wx, wy, wr, wsx, wsy)
    self._worldPosX = wx
    self._worldPosY = wy
    self._worldRotate = wr
    self._worldScaleX = wsx
    self._worldScaleY = wsy
    self._worldIsDirty = true
end

--- 增加一个待应用于世界空间的偏移（供 EntityMovementSys 在需要时调用）
---@param dx number
---@param dy number
function TransformCMP:addPendingWorldTranslate(dx, dy)
    self._pendingWorldDX = self._pendingWorldDX + dx
    self._pendingWorldDY = self._pendingWorldDY + dy
end

--- 消耗并返回累计的世界空间平移偏移（读取后清零）
---@return number, number
function TransformCMP:consumePendingWorldTranslate()
    local dx, dy = self._pendingWorldDX, self._pendingWorldDY
    self._pendingWorldDX = 0
    self._pendingWorldDY = 0
    return dx, dy
end

return {
    TransformCMP = TransformCMP,
}

