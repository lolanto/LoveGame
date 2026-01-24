
--- @class BaseComponent
--- @field _typeID number 组件类型ID
--- @field _entity Entity|nil 组件当前绑定的Entity
local BaseComponent = {}
BaseComponent.__index = BaseComponent
BaseComponent.static = {}
BaseComponent.static.RegisteredTypeCount = 0
BaseComponent.static.RegisterTypes_nameToID = {}
BaseComponent.static.RegisterTypes_IDToName = {}

--- cst，构造一个组件类
--- @param typeName string 组件类型名字
function BaseComponent:new(typeName)
    local instance  = setmetatable({}, self)
    instance._typeID = BaseComponent.static.RegisterTypes_nameToID[typeName]
    instance._entity = nil
    return instance
end

--- 获取当前组件绑定的实体
--- @return Entity|nil
function BaseComponent:getEntity()
    return self._entity
end

--- 获取当前组件绑定的实体，只读版，但暂时没有发挥作用
--- @return Entity|nil
function BaseComponent:getEntity_const()
    return require("utils.ReadOnly").makeReadOnly(self._entity)
end

--- 当组件绑定到Entity时调用
--- @param entity Entity 绑定的实体
function BaseComponent:onBound(entity)
    -- default do nothing
end

--- [TimeRewind] 获取组件的回溯状态
--- 返回包含组件关键数据的表，若不支持回溯则返回nil
--- @return table|nil
function BaseComponent:getRewindState_const()
    return nil
end

--- [TimeRewind] 恢复组件的回溯状态
--- @param state table 从getRewindState获取的状态数据
function BaseComponent:restoreRewindState(state)
    -- default do nothing
end

--- [TimeRewind] 插值回溯状态 (混合两个状态)
--- @param stateA table 较早的状态
--- @param stateB table 较晚的状态
--- @param t number 插值因子 [0, 1]
function BaseComponent:lerpRewindState(stateA, stateB, t)
    self:restoreRewindState(stateA)
end

--- 注册一个类型信息，并返回这个类型的类型id
--- 假如类型已经存在会抛出异常
--- @param typeName string
--- @return number
function BaseComponent.RegisterType(typeName)
    assert(type(typeName) == 'string', string.format('Type name using to register should be String! But %s produce', type(typeName)))
    assert(BaseComponent.static.RegisterTypes_nameToID[typeName] == nil, string.format('Their is already registered key %s', typeName))
    local BaseComponentID = BaseComponent.static.RegisteredTypeCount
    BaseComponent.static.RegisterTypes_nameToID[typeName] = BaseComponentID
    BaseComponent.static.RegisterTypes_IDToName[BaseComponentID] = typeName
    BaseComponent.static.RegisteredTypeCount = BaseComponent.static.RegisteredTypeCount + 1
    return BaseComponent.static.RegisterTypes_nameToID[typeName]
end

--- 辅助函数，从类型名字返回这个类型的ID
--- @param typeName string
--- @return number
function BaseComponent.GetTypeIDFromName(typeName)
    local retID = BaseComponent.static.RegisterTypes_nameToID[typeName]
    assert(retID ~= nil, string.format('BaseComponent type %s is not exist!', typeName))
    return retID
end

--- 辅助函数，从类型ID返回类型的名字
--- @param typeID number
--- @return string
function BaseComponent.GetTyepNameFromID(typeID)
    local retName = BaseComponent.static.RegisterTypes_IDToName[typeID]
    return retName
end

---检查给定的type是否存在
---@param typeInfo string|number
---@return string|number|nil 假如存在，就返回类型名称(假如输入ID)或者ID(假如输入名称)，否则返回nil 
function BaseComponent.CheckTypeExistence(typeInfo)
    if (type(typeInfo) == "number") then
        return BaseComponent.GetTyepNameFromID(typeInfo)
    elseif (type(typeInfo) == "string") then
        return BaseComponent.GetTypeIDFromName(typeInfo)
    end
    return nil
end

--- 获取组件的typeID
--- @return number
function BaseComponent:getTypeID()
    return self._typeID
end

--- 获取组件的类型名称
--- @return string
function BaseComponent:getTypeName()
    return BaseComponent.GetTyepNameFromID(self._typeID)
end

--- update方法
--- @param deltaTime number
function BaseComponent:update(deltaTime)
    -- do nothing
end

--- 判断当前实例是否是某个类型或其子类型的实例
--- @param typeInfo string|number 要匹配的类型名或类型ID
--- @return boolean
function BaseComponent:isInstanceOf(typeInfo)
    local targetName = nil
    if (type(typeInfo) == "number") then
        targetName = BaseComponent.GetTyepNameFromID(typeInfo)
    elseif (type(typeInfo) == "string") then
        targetName = typeInfo
    else
        assert(false, 'typeInfo should be string or number!')
    end
    -- 从实例的元表开始，沿着类的继承链查找 ComponentTypeName
    local mt = getmetatable(self)
    while mt do
        if mt.ComponentTypeName == targetName then
            return true
        end
        mt = getmetatable(mt)
    end
    return false
end

--- 判断一个类表是否是某个类型或其子类
--- @param classTable table 要检查的类表
--- @param typeInfo string|number 要匹配的类型名或类型ID
--- @return boolean
function BaseComponent.classIsSubclassOf(classTable, typeInfo)
    local targetName = nil
    if (type(typeInfo) == "number") then
        targetName = BaseComponent.GetTyepNameFromID(typeInfo)
    elseif (type(typeInfo) == "string") then
        targetName = typeInfo
    else
        return false
    end
    local mt = classTable
    while mt do
        if mt.ComponentTypeName == targetName then
            return true
        end
        mt = getmetatable(mt)
    end
    return false
end

return {
    BaseComponent = BaseComponent,
}
