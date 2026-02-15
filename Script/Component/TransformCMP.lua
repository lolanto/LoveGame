--[[
    TransformCMP.lua
    描述: 变换组件，提供位移、旋转、缩放等变换功能

    TODO: 应该提供两个Transform，一个是本地变换，一个是全局变换。其中全局变换需要每帧计算获得

    love2d的Transform矩阵是列矩阵
    | e0 e4 e8  e12 |
    | e1 e5 e9  e13 |
    | e2 e6 e10 e14 |
    | e3 e7 e11 e15 |
    矩阵和矩阵相乘时，API love2d.math.transform:apply(other), self * other
    矩阵和向量相乘时，API love2d.math.transform:transformPoint(x,y), self * vec 此处vec是列向量！

    更新的原则是，所有的set都不会立即刷新，只有等到get的时候才会刷新所有数据

    TODO：请检查所有的实现！现在只是一个半成品
--]]


local MOD_BaseComponent = require('BaseComponent').BaseComponent
local MOD_Config = require('Config').Config

---@class TransformCMP : BaseComponent
---@field _posX number
---@field _posY number
---@field _rotate number
---@field _scaleX number
---@field _scaleY number
---@field _isDirty boolean
---@field _transform nil|love.Transform
---@field _worldPosX number
---@field _worldPosY number
---@field _worldRotate number
---@field _worldScaleX number
---@field _worldTransform nil|love.Transform
---@field _cacheID number 用于标记变换缓存是否有效，可以通过遍历整个TransformCMP树来判断
local TransformCMP = setmetatable({}, MOD_BaseComponent)
TransformCMP.__index = TransformCMP
TransformCMP.ComponentTypeName = "TransformCMP"
TransformCMP.ComponentTypeID = MOD_BaseComponent.RegisterType(TransformCMP.ComponentTypeName)


function TransformCMP:new()
    local instance = setmetatable(MOD_BaseComponent.new(self, TransformCMP.ComponentTypeName), self)
    -- 变换属性的单位，无论是局部还是世界，均以米为单位
    -- 局部变换属性
    instance._posX = 0
    instance._posY = 0
    instance._rotate = 0
    instance._scaleX = 1
    instance._scaleY = 1
    instance._isDirty = true
    instance._transform = nil
    -- 世界变换属性。注意，这些属性都只是缓存，假如TransformCMP的继承链条上，父节点存在修改，这些缓存值都将失效
    instance._worldPosX = 0
    instance._worldPosY = 0
    instance._worldRotate = 0
    instance._worldScaleX = 1
    instance._worldScaleY = 1
    instance._worldTransform = nil
    instance._parentCacheID = 0
    instance._selfCacheID = 0
    -- pending world-space translation accumulated externally (e.g. EntityMovementSys)
    instance._pendingWorldDX = 0
    instance._pendingWorldDY = 0
    return instance
end

---查询当前TransformCMP是否有修改未应用
---@return boolean 返回true表示有修改未应用
function TransformCMP:isLocalDirty_const()
    return self._isDirty
end

function TransformCMP:isParentCacheValid_const()
    return self._parentCacheID == self:collectParentCacheIDs_const()
end

function TransformCMP:isWorldDirty_const()
    return self:isLocalDirty_const() == true or self:isParentCacheValid_const() == false
end

function TransformCMP:getCacheID_const()
    return self._selfCacheID
end

---获取位移情况（只读版本）
---@return number,number 返回x和y的位移(局部空间)
function TransformCMP:getTranslate_const()
    return self._posX, self._posY
end

---获取缩放情况（只读版本）
---@return number,number 返回x和y轴的缩放程度(局部空间)
function TransformCMP:getScale_const()
    return self._scaleX, self._scaleY
end

---获取旋转情况（只读版本）
---@return number 返回旋转的角度(局部空间)
function TransformCMP:getRotate_const()
    return self._rotate
end

---获取世界坐标（只读版本）
---@return number, number 返回世界x和y
function TransformCMP:getWorldPosition_const()
    if MOD_Config.IS_DEBUG then
        assert(self:isWorldDirty_const() == false, "Attempt to get const world position while dirty!")
    end
    return self._worldPosX, self._worldPosY
end

---获取世界缩放（只读版本）
---@return number, number 返回世界缩放x和y
function TransformCMP:getWorldScale_const()
    if MOD_Config.IS_DEBUG then
        assert(self:isWorldDirty_const() == false, "Attempt to get const world scale while dirty!")
    end
    return self._worldScaleX, self._worldScaleY
end

---获取世界旋转（只读版本）
---@return number 返回世界旋转角度
function TransformCMP:getWorldRotate_const()
    if MOD_Config.IS_DEBUG then
        assert(self:isWorldDirty_const() == false, "Attempt to get const world rotate while dirty!")
    end
    return self._worldRotate
end

---设置局部空间位移大小
---@param x number x轴向位移
---@param y number y轴向位移
function TransformCMP:setPosition(x, y)
    assert(x ~= nil and y ~= nil)
    self._posX = x
    self._posY = y
    self._isDirty = true
end

---设置局部空间位移偏移大小
---@param dx number x轴向位移偏移
---@param dy number y轴向位移偏移
function TransformCMP:translate(dx, dy)
    assert(dx ~= nil and dy ~= nil)
    self._posX = self._posX + dx
    self._posY = self._posY + dy
    self._isDirty = true
end

---设置局部空间缩放大小
---@param x number x轴向的缩放大小
---@param y number y轴向的缩放大小
function TransformCMP:setScale(x, y)
    assert(x ~= nil and y ~= nil)
    self._scaleX = x
    self._scaleY = y
    self._isDirty = true
end

---设置局部空间旋转角度
---@param r number 旋转角度，正值为顺时针
function TransformCMP:setRotate(r)
    assert(r ~= nil, "rotate value must not be nil")
    self._rotate = r
    self._isDirty = true
end

function TransformCMP:collectParentCacheIDs_const()
    ---@type Entity
    local entity = self:getEntity_const()
    assert(entity ~= nil, "TransformCMP has no owner entity!")
    ---@type Entity
    local parentEntity = entity:getParent_const()
    ---@type TransformCMP
    local parentTransformCMP = nil
    if parentEntity ~= nil then
        parentTransformCMP = parentEntity:getComponent_const('TransformCMP')
    end
    if parentTransformCMP ~= nil then
        local parentDirty = parentTransformCMP:isLocalDirty_const()
        if parentDirty then
            return parentTransformCMP:collectParentCacheIDs_const() + parentTransformCMP:getCacheID_const() + 1
        else
            return parentTransformCMP:collectParentCacheIDs_const() + parentTransformCMP:getCacheID_const()
        end
    end
    return 0
end

function TransformCMP:updateLocalTransform()
    if self._isDirty then
        -- 更新局部变换矩阵
        local transform = love.math.newTransform()
        transform:translate(self._posX, self._posY)
        transform:rotate(self._rotate)
        transform:scale(self._scaleX, self._scaleY)
        self._transform = transform
        self._isDirty = false
        -- 更新缓存ID
        self._selfCacheID = self._selfCacheID + 1
    end
end

---更新World变换矩阵
---@return nil
function TransformCMP:updateWorldTransform()
    ---从自身的局部变换和父节点的世界变换计算出自己的世界变换属性
    self:updateLocalTransform()
    local parentWorldTransform = self:getParentTransform()
    self._worldTransform = parentWorldTransform:clone():apply(self._transform)
    -- 从世界变换矩阵中分解出位置、旋转、缩放属性
    local f_mat1_1, f_mat1_2, f_mat1_3, f_mat1_4
            , f_mat2_1, f_mat2_2, f_mat2_3, f_mat2_4
            , f_mat3_1, f_mat3_2, f_mat3_3, f_mat3_4
            , f_mat4_1, f_mat4_2, f_mat4_3, f_mat4_4 = self._worldTransform:getMatrix()
    self._worldPosX = f_mat1_4
    self._worldPosY = f_mat2_4
    self._worldScaleX = math.sqrt(f_mat1_1 * f_mat1_1 + f_mat2_1 * f_mat2_1)
    self._worldScaleY = math.sqrt(f_mat1_2 * f_mat1_2 + f_mat2_2 * f_mat2_2)
    self._worldRotate = math.atan2(f_mat2_1, f_mat1_1)
    -- 更新父节点缓存ID
    self._parentCacheID = self:collectParentCacheIDs_const()
end

---更新所有的变换信息
---@return nil
function TransformCMP:updateTransforms()
    local shouldUpdate = self:isWorldDirty_const()
    if shouldUpdate then
        -- 更新局部变换矩阵
        self:updateLocalTransform()
        -- 更新世界变换矩阵
        self:updateWorldTransform()
    end
end

---返回局部变换矩阵情况。若有修改，会尝试更新局部变换矩阵
---@return love.Transform 返回局部变换矩阵
function TransformCMP:getLocalTransform()
    self:updateTransforms()
    return self._transform
end

---返回局部变换矩阵情况（只读版本）
---@return love.Transform 返回局部变换矩阵
---@note 假如矩阵明确有修改，请调用updateLocalTransform先更新，或者调用非const版本
function TransformCMP:getLocalTransform_const()
    assert(self:isLocalDirty_const() == false, "Attempt to get const local transform while dirty!")
    return self._transform
end

---返回世界变换矩阵。若有修改，会尝试更新世界变换矩阵
---@return love.Transform 返回世界变换矩阵（由TransformUpdateSystem维护的世界属性生成）
function TransformCMP:getWorldTransform()
    self:updateTransforms()
    return self._worldTransform
end

---返回世界变换矩阵（只读版本）
---@return love.Transform 返回世界变换矩阵（由TransformUpdateSystem维护的世界属性生成）
---@note 假如矩阵明确有修改，请调用updateWorldTransform先更新，或者调用非const版本
function TransformCMP:getWorldTransform_const()
    assert(self:isWorldDirty_const() == false, "Attempt to get const world transform while dirty!")
    return self._worldTransform
end

function TransformCMP:setWorldPosition(wx, wy)
    -- 将世界空间位置转换为局部空间位置
    local parentTransform = self:getParentTransform()
    local invParentTransform = parentTransform:inverse()
    local lx, ly = invParentTransform:transformPoint(wx, wy)
    self:setPosition(lx, ly)
end

function TransformCMP:translateWorldPosition(dwx, dwy)
    -- 将世界空间位移转换为局部空间位移
    local parentTransform = self:getParentTransform()
    local invParentTransform = parentTransform:inverse()
    local lx1, ly1 = invParentTransform:transformPoint(0, 0)
    local lx2, ly2 = invParentTransform:transformPoint(dwx, dwy)
    local ldx, ldy = lx2 - lx1, ly2 - ly1
    self:translate(ldx, ldy)
end

function TransformCMP:setWorldRotate(wr)
    -- 将世界空间旋转转换为局部空间旋转
    local parentTransform = self:getParentTransform()
    local f_mat1_1, f_mat1_2, f_mat1_3, f_mat1_4
            , f_mat2_1, f_mat2_2, f_mat2_3, f_mat2_4
            , f_mat3_1, f_mat3_2, f_mat3_3, f_mat3_4
            , f_mat4_1, f_mat4_2, f_mat4_3, f_mat4_4 = parentTransform:getMatrix()
    local pr = math.atan2(f_mat2_1, f_mat1_1)
    local lr = wr - pr
    self:setRotate(lr)
end

--- 获取父节点共同构成的世界变换矩阵
---@note 这个函数会触发父节点的TransformCMP更新，确保获取到最新的变换矩阵
---@return love.math.Transform 返回父节点的世界变换矩阵，若无父节点则返回单位矩阵
function TransformCMP:getParentTransform()
    local entity = self:getEntity()
    assert(entity ~= nil, "TransformCMP has no owner entity!")
    local parentEntity = entity.getParent and entity:getParent()
    ---@type TransformCMP
    local parentTransformCMP = nil
    if parentEntity ~= nil then
        parentTransformCMP = parentEntity:getComponent('TransformCMP')
    end
    if parentTransformCMP ~= nil then
        return parentTransformCMP:getWorldTransform()
    end
    return love.math.newTransform()
end

-- [TimeRewind] 获取组件的回溯状态
-- 返回包含组件关键数据的表，若不支持回溯则返回nil
function TransformCMP:getRewindState_const()
    return {
        x = self._posX,
        y = self._posY,
        r = self._rotate,
        sx = self._scaleX,
        sy = self._scaleY
    }
end

function TransformCMP:restoreRewindState(state)
    if not state then return end
    self:setPosition(state.x, state.y)
    self:setRotate(state.r)
    self:setScale(state.sx, state.sy)
end

function TransformCMP:lerpRewindState(stateA, stateB, t)
    if not stateA or not stateB then return end
    
    -- Linear interpolation for position and scale
    local x = stateA.x + (stateB.x - stateA.x) * t
    local y = stateA.y + (stateB.y - stateA.y) * t
    local sx = stateA.sx + (stateB.sx - stateA.sx) * t
    local sy = stateA.sy + (stateB.sy - stateA.sy) * t
    
    -- Handle rotation wrapping for interpolation
    local rA = stateA.r
    local rB = stateB.r
    local diff = rB - rA
    while diff < -math.pi do diff = diff + 2 * math.pi end
    while diff > math.pi do diff = diff - 2 * math.pi end
    local r = rA + diff * t
    
    self:setPosition(x, y)
    self:setRotate(r)
    self:setScale(sx, sy)
end

return {
    TransformCMP = TransformCMP,
}

