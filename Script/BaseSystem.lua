---@class ComponentRequirementDesc
---@field _mustHave boolean 该组件是否为必须组件
---@field _readOnly boolean 该组件是否为只读组件
local ComponentRequirementDesc = {}
ComponentRequirementDesc.__index = ComponentRequirementDesc

function ComponentRequirementDesc:new(mustHave, readOnly)
    local instance = setmetatable({}, ComponentRequirementDesc)
    instance._mustHave = mustHave
    instance._readOnly = readOnly
    return instance
end


---@class BaseSystem
---@field _nameOfSystem string
---@field _requiredComponentInfos {string:ComponentRequirementDesc}
---@field _collectedComponents {string:[BaseComponent]}
local BaseSystem = {}
BaseSystem.__index = BaseSystem

---cst, 系统构造函数
---@param nameOfSystem string 系统名称
function BaseSystem:new(nameOfSystem)
    local instance = setmetatable({}, self)
    instance._nameOfSystem = nameOfSystem
    instance._requiredComponentInfos = {}
    instance._collectedComponents = {}
    return instance
end



---增加组件的请求信息，假如组件信息已存在，则可修改其required
---@param componentInfo string|number 组件的描述信息，组件名称或者ID
---@param requirementDesc ComponentRequirementDesc 组件需求描述
---@return nil
function BaseSystem:addComponentRequirement(componentInfo, requirementDesc)
    local MOD_BaseComponent = require('BaseComponent').BaseComponent
    local cmpInfo2 = MOD_BaseComponent.CheckTypeExistence(componentInfo)
    assert(cmpInfo2 ~= nil, 'Component is not exist!')
    if (type(cmpInfo2) == 'string') then 
        self._requiredComponentInfos[cmpInfo2] = requirementDesc
    else
        self._requiredComponentInfos[componentInfo] = requirementDesc
    end
end

---移除组件的请求信息
---@param componentInfo string|number 组件的描述信息，组件名称或者ID
---@return nil
function BaseSystem:removeComponentRequirement(componentInfo)
    local MOD_BaseComponent = require('BaseComponent').BaseComponent
    local cmpInfo2 = MOD_BaseComponent.CheckTypeExistence(componentInfo)
    assert(cmpInfo2 ~= nil, 'Component is not exist!')
    if (type(cmpInfo2) == 'string') then 
        self._requiredComponentInfos[cmpInfo2] = nil
    else
        self._requiredComponentInfos[componentInfo] = nil
    end
end

function BaseSystem:preCollect()
    self._collectedComponents = {}
    for componentName, requirementDesc in pairs(self._requiredComponentInfos) do
        self._collectedComponents[componentName] = {}
    end
end

---从entity身上去收集组件
---@param entity Entity 目标Entity，将会从这个entity身上搜集组件
---@return boolean 搜集成功返回true，否则返回false
function BaseSystem:collect(entity)
    local ignoreThisEntity = false
    local errorOccurred = false
    local collectedComponents = {}
    for componentName, requirementDesc in pairs(self._requiredComponentInfos) do
        local retCmp = entity:getComponent(componentName)
        collectedComponents[componentName] = retCmp
        if retCmp == nil and requirementDesc._mustHave then
            ignoreThisEntity = true
            break
        end
    end
    if ignoreThisEntity then
        errorOccurred = false
    else
        for componentName, component in pairs(collectedComponents) do
            local requirementDesc = self._requiredComponentInfos[componentName]
            if requirementDesc._readOnly and component ~= nil then
                component = require('utils.ReadOnly').makeComponentReadOnly(component)
            end
            table.insert(self._collectedComponents[componentName], component)
        end
    end
    return not errorOccurred
end

function BaseSystem:tick(deltaTime)
    -- do nothing
end

function BaseSystem:draw()
    -- do nothing
end


return {
    BaseSystem = BaseSystem,
    ComponentRequirementDesc = ComponentRequirementDesc
}
