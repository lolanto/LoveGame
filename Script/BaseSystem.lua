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
---@param world World World单例
function BaseSystem:new(nameOfSystem, world)
    local o = {}
    local instance = setmetatable(o, self)
    instance._nameOfSystem = nameOfSystem
    instance._requiredComponentInfos = {}
    instance._componentsView = nil
    instance._world = world
    return instance
end

--- 初始化View，必须在添加完所有组件需求后调用
function BaseSystem:initView()
    if self._componentsView then return end
    if not self._world then error("World is not set in BaseSystem") end
    self._componentsView = self._world:getComponentsView(self._requiredComponentInfos)
end

--- 获取当前系统对应的ComponentsView
---@return ComponentsView
function BaseSystem:getComponentsView()
    return self._componentsView
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
   -- Deprecated
end

---从entity身上去收集组件
---@deprecated View mode no longer uses collect()
function BaseSystem:collect(entity)
    -- Deprecated
    return true
end

function BaseSystem:tick(deltaTime)
    -- do nothing
end

function BaseSystem:draw()
    -- do nothing
end

function BaseSystem:processUserInput(userInteractController)
    -- do nothing
end

return {
    BaseSystem = BaseSystem,
    ComponentRequirementDesc = ComponentRequirementDesc
}
