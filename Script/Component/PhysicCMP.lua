--[[
    TODO: love2d的物理API规则是：先创建一个world，然后在这个world里创建body，再在body上创建fixture，最后在fixture上创建shape。
    目前这个PhysicCMP只是一个空壳，后续需要补充对body/fixture/shape的创建和管理逻辑。

    TODO: 现在每个Entity之间可以挂父子关系，假如这些Entity身上又有各自的物理组件，那么这些物理组件之间的关系应该如何处理？
    Love2d的物理组件是没有父子关系的！它们有各种各样的约束关系(xx joint)，比如距离约束、铰链约束等等，但是没有父子关系。

    TODO: 理论上绑定了物理组件的Entity，他的Transform最后是根据物理系统的结算来更新的。那和现如今的MovementCMP应该如何协调呢？
    正常来说应该是Gameplay逻辑先起作用-> MovementCMP更新Entity位置-> PhysicCMP更新物理组件位置-> PhysicSys结算物理世界-> PhysicCMP再更新Entity位置
    看着很奇怪：
    * 假如同时有MovementCMP和PhysicCMP，MovementCMP先更新位置，然后PhysicCMP会在这个基础上再进行更新
    * 假如只有PhysicCMP，那么PhysicCMP也会更新Entity位置
--]]

---@class Shape
---@field _type string 形状类型描述
---@field _density number 形状的密度?
---@field _love_shape love.physics.Shape|nil love2d的物理形状对象
local Shape = setmetatable({}, {})
Shape.__index = Shape
Shape.static = {}
Shape.static.Type = {
    CIRCLE = "circle",
    RECTANGLE = "rectangle",
}

-- Shape base class and two concrete shape classes: Circle and Rectangle.
-- These are lightweight descriptor objects that know how to create
-- the corresponding love2d shape when asked.

-- Base constructor
---@param type string 类型描述
---@param density number 形状的密度，和形状的面积一起，影响其质量。最终会影响速度/位置的解算！
function Shape:new(type, density)
    local instance = setmetatable({}, self)
    instance._type = type
    instance._density = density
    instance._love_shape = nil
    return instance
end

function Shape:getType_const()
    return self._type
end

function Shape:getDensity_const()
    return self._density
end

function Shape:getLoveShape()
    return self._love_shape
end

---@class Circle : Shape
---@field _radius number 半径
---@field _offsetX number x方向偏移
---@field _offsetY number y方向偏移
local Circle = setmetatable({}, Shape)
Circle.__index = Circle

--- Constructor: Circle:new(radius, offsetX, offsetY, density)
function Circle:new(radius, offsetX, offsetY, density)
    assert(radius and type(radius) == 'number', "Circle requires numeric radius")
    local instance = setmetatable(Shape.new(self, Shape.static.Type.CIRCLE, density or 1), self)
    instance._radius = radius
    instance._offsetX = offsetX or 0
    instance._offsetY = offsetY or 0

    if instance._offsetX ~= 0 or instance._offsetY ~= 0 then
        instance._love_shape = love.physics.newCircleShape(instance._offsetX, instance._offsetY, instance._radius)
    else
        instance._love_shape = love.physics.newCircleShape(instance._radius)
    end

    return instance
end

---@class Rectangle : Shape
---@field _width number 宽度
---@field _height number 高度
---@field _offsetX number x方向偏移
---@field _offsetY number y方向偏移
---@field _angle number 旋转角度，弧度制
local Rectangle = setmetatable({}, Shape)
Rectangle.__index = Rectangle

--- Constructor: Rectangle:new(width, height, offsetX, offsetY, angle, density)
function Rectangle:new(width, height, offsetX, offsetY, angle, density)
    assert(width and height and type(width) == 'number' and type(height) == 'number', "Rectangle requires numeric width and height")
    local instance = setmetatable(Shape.new(self, Shape.static.Type.RECTANGLE, density or 0), self)
    instance._width = width
    instance._height = height
    instance._offsetX = offsetX or 0
    instance._offsetY = offsetY or 0
    instance._angle = angle or 0

    if instance._offsetX ~= 0 or instance._offsetY ~= 0 or instance._angle ~= 0 then
        instance._love_shape = love.physics.newRectangleShape(instance._offsetX, instance._offsetY, instance._width, instance._height, instance._angle)
    else
        instance._love_shape = love.physics.newRectangleShape(instance._width, instance._height)
    end

    return instance
end

function Rectangle:getWidth_const()
    return self._width
end

function Rectangle:getHeight_const()
    return self._height
end

-- Expose constructors on Shape for convenience
Shape.static.Circle = function(radius, offsetX, offsetY, density) return Circle:new(radius, offsetX, offsetY, density) end
Shape.static.Rectangle = function(width, height, offsetX, offsetY, angle, density) return Rectangle:new(width, height, offsetX, offsetY, angle, density) end


local MOD_BaseComponent = require('BaseComponent').BaseComponent

---@class PhysicCMP : BaseComponent
---@field _body love.physics.Body|nil love2d的物理系统对象：body
---@field _fixture love.physics.Fixture|nil love2d的物理系统对象: fixture
---@field _shape Circle|Rectangle 物理形状描述对象
---@field _world love.physics.World
local PhysicCMP = setmetatable({}, MOD_BaseComponent)
PhysicCMP.__index = PhysicCMP
PhysicCMP.ComponentTypeName = "PhysicCMP"
PhysicCMP.ComponentTypeID = MOD_BaseComponent.RegisterType(PhysicCMP.ComponentTypeName)


---cst
---@param world love.physics.World love2d的物理世界对象
---@param opts table|nil 可选参数表
function PhysicCMP:new(world, opts)
    -- opts (optional) usage:
    -- {
    --   bodyType = "dynamic", -- "dynamic"|"static"|"kinematic"
    --   shape = Shape.Circle(radius) or Shape.Rectangle(w,h)
    -- }
    local instance = setmetatable(MOD_BaseComponent.new(self, PhysicCMP.ComponentTypeName), self)

    instance._body = nil
    instance._fixture = nil
    instance._shape = nil
    instance._world = world  -- love.physics.World实例

    opts = opts or {}
    
    instance._shape = opts.shape
    assert(type(instance._shape) == 'table'
        and instance._shape.getLoveShape 
        and instance._shape:getLoveShape() ~= nil, "PhysicCMP requires a valid shape descriptor")

    -- Only try to create physics objects if a world and shape descriptor are provided
    if instance._world and instance._shape then
        local bodyType = opts.bodyType or "dynamic"

        -- create love body
        instance._body = love.physics.newBody(world, 0, 0, bodyType)
        
        if opts.fixedRotation ~= nil then
            instance._body:setFixedRotation(opts.fixedRotation)
        end

        -- create fixture; use density from shape descriptor or opts
        local density = instance._shape:getDensity_const()
        instance._fixture = love.physics.newFixture(instance._body, instance._shape:getLoveShape(), density)

    end

    return instance
end

function PhysicCMP:getEntity()
    return self._entity
end

--- 当组件绑定到Entity时调用
function PhysicCMP:onBound(entity)
    assert(entity == self._entity, "PhysicCMP:onBound called with different entity than current one")
    if self._fixture then
        self._fixture:setUserData(entity)
    end
    if self._body then
        -- 同时给Body也设置UserData，以防PhysicSys中只获取到了Body
        self._body:setUserData(entity)
    end
end


---判断物理组件的Body是否为静态类型
---@return boolean 是否为静态类型
function PhysicCMP:isBodyStatic_const()
    if self._body then
        return self._body:getType() == "static"
    end
    return false
end

function PhysicCMP:getShape_const()
    return require('utils.ReadOnly').makeReadOnly(self._shape)
end

function PhysicCMP:getShape()
    return self._shape
end

function PhysicCMP:getBody()
    return self._body
end

---设置物理组件的位置(世界空间)
---@param x number x坐标
---@param y number y坐标
function PhysicCMP:setBodyPosition(x, y)
    if self._body then
        self._body:setPosition(x, y)
    end
end

---返回Body的位置(世界空间)
---@return number|nil x, number|nil y 位置坐标，假如body不存在则返回nil
function PhysicCMP:getBodyPosition()
    if self._body then
        return self._body:getPosition()
    end
    return nil, nil
end

---设置物理组件的旋转(世界空间，弧度)
---@param r number 旋转角度，弧度制
function PhysicCMP:setBodyRotate(r)
    if self._body then
        self._body:setAngle(r)
    end
end

---返回Body的旋转(世界空间，弧度)
---@return number|nil r 旋转角度，弧度制，假如
function PhysicCMP:getBodyRotate()
    if self._body then
        return self._body:getAngle()
    end
    return nil
end

---设置是否固定旋转（不受外力影响发生旋转）
---@param fixed boolean 是否固定
function PhysicCMP:setFixedRotation(fixed)
    if self._body then
        self._body:setFixedRotation(fixed)
    end
end

---获取是否固定旋转
---@return boolean
function PhysicCMP:isFixedRotation_const()
    if self._body then
        return self._body:isFixedRotation()
    end
    return false
end

--- [TimeRewind] 获取组件的回溯状态
--- 返回包含组件关键数据的表，若不支持回溯则返回nil
function PhysicCMP:getRewindState_const()
    if not self._body or self._body:isDestroyed() then return nil end
    local vx, vy = self._body:getLinearVelocity()
    local av = self._body:getAngularVelocity()
    return {
        vx = vx,
        vy = vy,
        angVel = av
    }
end

function PhysicCMP:restoreRewindState(state)
    if not state then return end
    if not self._body or self._body:isDestroyed() then return end
    
    self._body:setLinearVelocity(state.vx, state.vy)
    self._body:setAngularVelocity(state.angVel)
end

function PhysicCMP:lerpRewindState(stateA, stateB, t)
    if not self._body or self._body:isDestroyed() then return end
    if not stateA or not stateB then return end

    -- 线性插值线性速度
    local vx = stateA.vx + (stateB.vx - stateA.vx) * t
    local vy = stateA.vy + (stateB.vy - stateA.vy) * t
    
    -- 线性插值角速度
    local angVel = stateA.angVel + (stateB.angVel - stateA.angVel) * t

    self._body:setLinearVelocity(vx, vy)
    self._body:setAngularVelocity(angVel)
end

--- 从Entity的Transform组件同步物理Body的位置和旋转
--- @note This method should be called when the Entity's Transform has changed and we need to update the physics body accordingly.
--- @return nil
function PhysicCMP:syncBodyTransformFromEntityTransform()
    if not self._body or self._body:isDestroyed() then return end
    local transformCmp = self._entity:getComponent_const('TransformCMP')
    if not transformCmp then return end
    
    local x, y = transformCmp:getWorldPosition_const()
    local r = transformCmp:getWorldRotate_const()
    self._body:setPosition(x, y)
    self._body:setAngle(r)
end

return {
    PhysicCMP = PhysicCMP,
    Shape = Shape,
}

