
--- @class Entity
--- @field _nameOfEntity string
--- @field _components table<number, BaseComponent>
--- @field _childEntities Entity[]
--- @field _parentEntity Entity
--- @field _idToParentEntity number|nil
--- @field _boundingQuad nil
--- @field _isVisible boolean
--- @field _isEnable boolean
local Entity = {}
Entity.__index = Entity

--- cst, 构造entity对象
--- @param nameOfEntity string entity的名称
function Entity:new(nameOfEntity)
    local instance = setmetatable({}, self)
    instance._nameOfEntity = nameOfEntity -- Entity的名称
    instance._components = {} -- Entity所绑定的组件
    instance._childEntities = {} -- Entity的子Entity
    instance._parentEntity = nil -- Entity的父Entity
    instance._idToParentEntity = nil -- 当前Entity在父Entity的childEntities数组中的下标
    instance._boundingQuad = nil -- Entity的包围盒
    instance._isVisible = false -- 当前Entity是否可见
    instance._isEnable = false -- 当前Entity是否被激活
    return instance
end

--- 绑定一个组件会检查是否已经绑定了同类组件并报错
--- @param inputComponent BaseComponent 需要绑定的组件
--- @return nil
function Entity:boundComponent(inputComponent)
    assert(inputComponent._entity == nil, 'Component using to bound does not be unbounded!')
    local typeID = inputComponent:getTypeID()
    assert(self._components[typeID] == nil, 'There is an already component bound to this entity!')
    self._components[typeID] = inputComponent
    inputComponent._entity = self
end

--- 绑定或者替换一个已有的组件
--- 假如发生了替换，就返回被替换的组件。否则返回nil
--- @param inputComponent BaseComponent 需要绑定的组件
--- @return BaseComponent|nil
function Entity:boundOrReplaceComponent(inputComponent)
    assert(inputComponent._entity == nil, 'Component using to bound does not be unbounded!')
    inputComponent._entity = self
    local typeID = inputComponent:getTypeID()
    if self._components[typeID] ~= nil then
        -- 发生替换
        local oldComponent = self._components[typeID]
        self._components[typeID] = inputComponent
        oldComponent._entity = nil
        return oldComponent
    else
        self._components[typeID] = inputComponent
        return nil
    end
    return nil
end

--- 取消一个组件的绑定，并返回取消绑定的组件
--- @param componentTypeID number 需要解除绑定的组件的类型ID
--- @return BaseComponent|nil
function Entity:unboundComponent(componentTypeID)
    local retComp = nil
    retComp = self._components[componentTypeID]
    if retComp ~= nil then
        self._components[componentTypeID] = nil
    end
    retComp._entity = nil
    return retComp
end

--- 获取指定类型的组件对象
--- @param componentType string|number 要获取的组件的信息，名称或者ID
--- @return BaseComponent|nil 返回组件对象，或者找不到返回nil
function Entity:getComponent(componentType)
    if (type(componentType) == "number") then
        return self._components[componentType]
    elseif (type(componentType) == "string") then
        local BaseComponent = require('BaseComponent')
        local cmpID = BaseComponent.GetTypeIDFromName(componentType)
        assert(cmpID ~= nil, string.format('Component type %s is not exist', componentType))
        return self._components[cmpID]
    end
end

--- 判断是否包含指定的组件
--- @param componentType string|number 要获取的组件信息，名称或者ID
--- @return boolean True假如组件存在，否则False
function Entity:hasComponent(componentType)
    return self:getComponent(componentType) ~= nil
end

function Entity:boundChildEntity(childEntity)
end

function Entity:unboundChildEntity(childEntity)
end

function Entity:setIDToParentEntity(inputID)
    self.idToParentEntity = inputID
end

--- update实体
--- @param deltaTime number 两次tick之间的间隔时间(second)
function Entity:update(deltaTime)
end

return Entity