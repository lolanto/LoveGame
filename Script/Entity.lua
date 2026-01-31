
--- @class Entity
--- @field _nameOfEntity string
--- @field _components table<number, BaseComponent>
--- @field _childEntities Entity[]
--- @field _parentEntity Entity
--- @field _idToParentEntity number|nil
--- @field _boundingQuad nil
--- @field _isVisible boolean
--- @field _isEnable boolean
--- @field _needRewind boolean
--- @field _level Level|nil ReadOnly
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
    instance._needRewind = false -- 是否需要回溯
    instance._level = nil -- Entity所属的Level ReadOnly
    return instance
end

--- 获取实体的名称
--- @return string
function Entity:getName_const()
    return self._nameOfEntity
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
    inputComponent:onBound(self)
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
        inputComponent:onBound(self)
        return oldComponent
    else
        self._components[typeID] = inputComponent
        inputComponent:onBound(self)
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
function Entity:getComponent_const(componentType)
    ---@type number
    local cmpID = nil
    ---@type string
    local cmpName = nil
    if (type(componentType) == "number") then
        cmpID = componentType
        cmpName = require('BaseComponent').BaseComponent.GetTyepNameFromID(componentType)
        assert(cmpName ~= nil, string.format('Component type ID %d is not exist', componentType))
    elseif (type(componentType) == "string") then
        cmpName = componentType
        cmpID = require('BaseComponent').BaseComponent.GetTypeIDFromName(componentType)
        assert(cmpID ~= nil, string.format('Component type %s is not exist', componentType))
    else
        assert(false, 'Invalid componentType parameter!')
    end
    -- try exact id first
    local exact = self._components[cmpID]
    if exact ~= nil then
        return require("utils.ReadOnly").makeReadOnly(exact)
    end
    -- 如果没有精确匹配，则将这个数字视作父类的ID，查找派生类组件
    for _, comp in pairs(self._components) do
        if comp ~= nil and comp:isInstanceOf(cmpName) then
            return require("utils.ReadOnly").makeReadOnly(comp)
        end
    end
    return nil
end

function Entity:getComponent(componentType)
    local comp = self:getComponent_const(componentType)
    if comp ~= nil then
        comp = comp:const_cast()
    end
    return comp
end

--- 判断是否包含指定的组件
--- @param componentType string|number 要获取的组件信息，名称或者ID
--- @return boolean True假如组件存在，否则False
function Entity:hasComponent(componentType)
    return self:getComponent(componentType) ~= nil
end

--- 获取所有匹配指定类型（或父类）的组件
--- @param componentType string|number 要获取的组件信息，名称或者ID
--- @return BaseComponent[] 返回匹配到的组件数组，找不到返回空表
function Entity:getComponents(componentType)
    local results = {}
    ---@type number
    local cmpID = nil
    ---@type string
    local cmpName = nil
    if (type(componentType) == "number") then
        cmpID = componentType
        cmpName = require('BaseComponent').BaseComponent.GetTyepNameFromID(componentType)
        assert(cmpName ~= nil, string.format('Component type ID %d is not exist', componentType))
    elseif (type(componentType) == "string") then
        cmpName = componentType
        cmpID = require('BaseComponent').BaseComponent.GetTypeIDFromName(componentType)
        assert(cmpID ~= nil, string.format('Component type %s is not exist', componentType))
    else
        assert(false, 'Invalid componentType parameter!')
    end

    -- collect exact match first
    local exact = self._components[cmpID]
    if exact ~= nil then
        table.insert(results, exact)
    end
    -- then collect any derived components
    for _, comp in pairs(self._components) do
        if comp ~= nil and comp:isInstanceOf(cmpName) then
            if comp ~= exact then
                table.insert(results, comp)
            end
        end
    end
    return results
end


--- 绑定子Entity，并自动设置父Entity
function Entity:boundChildEntity(childEntity)
    assert(childEntity ~= nil and childEntity ~= self)
    table.insert(self._childEntities, childEntity)
    childEntity._parentEntity = self
end


--- 解绑子Entity
function Entity:unboundChildEntity(childEntity)
    assert(childEntity ~= nil)
    for i, v in ipairs(self._childEntities) do
        if v == childEntity then
            table.remove(self._childEntities, i)
            childEntity._parentEntity = nil
            break
        end
    end
end
--- 获取父Entity
function Entity:getParent()
    return self._parentEntity
end

function Entity:getParent_const()
    return require("utils.ReadOnly").makeReadOnly(self._parentEntity)
end

--- 获取子Entity列表
function Entity:getChildren()
    return self._childEntities
end

function Entity:setIDToParentEntity(inputID)
    self.idToParentEntity = inputID
end

--- 设置是否进行回溯
--- @param val boolean
function Entity:setNeedRewind(val)
    self._needRewind = val
end

--- 检查是否需要回溯
--- @return boolean
function Entity:getNeedRewind_const()
    --- 回溯父节点，假如父节点需要回溯，则子节点也需要回溯
    local current = self
    while current do
        if current._needRewind then
            return true
        end
        current = current:getParent_const()
    end
    return false
end

--- update实体
--- @param deltaTime number 两次tick之间的间隔时间(second)
function Entity:update(deltaTime)
end

--- 进入关卡时的回调
--- @param level Level 进入的关卡 ReadOnly
function Entity:onEnterLevel(level)
    self._level = level
end

--- 离开关卡时的回调
function Entity:onLeaveLevel()
    self._level = nil
    --- 销毁所有组件
    for _, comp in pairs(self._components) do
        if comp ~= nil then
            comp:onUnbound()
            comp:onDestroy()
        end
    end
    self._components = {}
end

return Entity