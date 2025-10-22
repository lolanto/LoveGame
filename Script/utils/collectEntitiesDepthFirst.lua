-- 深度优先遍历所有Entity，返回有序数组
local function collectEntitiesDepthFirst(rootEntities)
    local result = {}
    local function dfs(entity)
        table.insert(result, entity)
        if entity.getChildren then
            for _, child in ipairs(entity:getChildren()) do
                dfs(child)
            end
        end
    end
    for _, root in ipairs(rootEntities) do
        dfs(root)
    end
    return result
end

return collectEntitiesDepthFirst
