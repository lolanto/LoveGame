---@class ComponentsView
---@field required string[]
---@field optional string[]
---@field components table<string, table> SoA Arrays
---@field entities Entity[]
local ComponentsView = {}

--- Sentinel for missing optional components
ComponentsView.EMPTY = {}

---@return function Iterator over (index, entity)
function ComponentsView:iterate() end

return {
    ComponentsView = ComponentsView
}
