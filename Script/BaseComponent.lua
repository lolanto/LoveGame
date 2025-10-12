
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

--- 注册一个类型信息，并返回这个类型的类型id
--- 假如类型已经存在会抛出异常
--- @param typeName string
--- @return number
function BaseComponent.RegisterType(typeName)
    assert(type(typeName) == 'string', string.format('Type name using to register should be String! But %s produce', type(typeName)))
    assert(BaseComponent.static.RegisterTypes_nameToID[typeName] == nil, string.format('Their is already registered key %s', typeName))
    local BaseComponentID = BaseComponent.RegisteredTypeCount
    BaseComponent.static.RegisterTypes_nameToID[typeName] = BaseComponentID
    BaseComponent.static.RegisterTypes_IDToName[BaseComponentID] = typeName
    BaseComponent.RegisteredTypeCount = BaseComponent.RegisteredTypeCount + 1
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

return BaseComponent
