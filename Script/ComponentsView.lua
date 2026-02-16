local ReadOnly = require('utils.ReadOnly')
local Config = require('Config')

---@class ComponentsView
---@field _viewKey string
---@field _requiredComponentInfo table<string, ComponentRequirementDesc>
---@field _entityIDs string[] Stores Entity IDs (for iteration and reverse map update)
---@field _entity_to_index table<string, number> EntityID -> Index
---@field _components table<string, table> SoA arrays
---@field _count number
local ComponentsView = {}
ComponentsView.__index = ComponentsView

ComponentsView.EMPTY = {}
if Config.Config.IS_DEBUG then
    ComponentsView.EMPTY = ReadOnly.makeReadOnly({})
end

---@param viewKey string
---@param requiredComponentInfo table<string, ComponentRequirementDesc>
function ComponentsView:new(viewKey, requiredComponentInfo)
    local instance = setmetatable({}, self)
    instance._viewKey = viewKey
    instance._requiredComponentInfo = requiredComponentInfo
    instance._entityIDs = {} -- Stores Entity IDs (instead of objects)
    instance._entity_to_index = {} -- Stores entityId -> index mapping
    instance._components = {} -- SoA: [ComponentName] -> {Component1, Component2, ...}
    instance._count = 0

    -- Initialize SoA arrays
    for cmpName, _ in pairs(requiredComponentInfo) do
        instance._components[cmpName] = {}
    end

    return instance
end

---@param entity Entity
function ComponentsView:add(entity)
    local entityID = entity:getID_const()
    if self._entity_to_index[entityID] then
        return -- Already exists
    end

    -- Verify requirements (Filter)
    for cmpName, reqDesc in pairs(self._requiredComponentInfo) do
        if reqDesc._mustHave and not entity:getComponent(cmpName) then
            return -- Requirement not met
        end
    end

    self._count = self._count + 1
    local index = self._count
    
    self._entityIDs[index] = entityID
    self._entity_to_index[entityID] = index

    for cmpName, reqDesc in pairs(self._requiredComponentInfo) do
        local component = entity:getComponent(cmpName)
        
        -- If component missing (optional case), use Sentinel
        if component == nil then
             self._components[cmpName][index] = ComponentsView.EMPTY
        else
            if reqDesc._readOnly then
                component = ReadOnly.makeComponentReadOnly(component)
            end
            self._components[cmpName][index] = component
        end
    end
end

---@param entity Entity
function ComponentsView:remove(entity)
    local entityID = entity:getID_const()
    local index = self._entity_to_index[entityID]
    if not index then return end

    local count = self._count

    -- Use table.remove to maintain order
    table.remove(self._entityIDs, index)
    
    -- Update SoA arrays
    for _, cmpArray in pairs(self._components) do
        table.remove(cmpArray, index)
    end
    
    -- Update reverse map
    self._entity_to_index[entityID] = nil
    
    -- Since we shifted everything from index+1 down by 1, update their map entries
    -- Optimization: Iterate from index to new count (which is old count - 1)
    for i = index, count - 1 do
        local movedID = self._entityIDs[i]
        self._entity_to_index[movedID] = i
    end

    self._count = count - 1
end

---@param requiredComponentInfos table<string, ComponentRequirementDesc>
---@return string
function ComponentsView.generateKey(requiredComponentInfos)
    local names = {}
    for name, _ in pairs(requiredComponentInfos) do
        table.insert(names, name)
    end
    table.sort(names)

    local keyParts = {}
    for _, name in ipairs(names) do
        local desc = requiredComponentInfos[name]
        -- Format: Name|M|R or Name|O|W
        local mFlag = desc._mustHave and "M" or "O"
        local rFlag = desc._readOnly and "R" or "W"
        table.insert(keyParts, string.format("%s|%s|%s", name, mFlag, rFlag))
    end
    
    return table.concat(keyParts, ";")
end

return ComponentsView
