-- TransformUpdateSys.lua
-- 根据父子关系更新Transform组件的世界变换

local MOD_BaseSystem = require('BaseSystem').BaseSystem
local TransformCMP = require('Component.TransformCMP').TransformCMP

---@class TransformUpdateSys : BaseSystem
local TransformUpdateSys = setmetatable({}, MOD_BaseSystem)
TransformUpdateSys.__index = TransformUpdateSys
TransformUpdateSys.SystemTypeName = "TransformUpdateSys"

function TransformUpdateSys:new(world)
    local instance = setmetatable(MOD_BaseSystem.new(self, TransformUpdateSys.SystemTypeName, world), self)
    local ComponentRequirementDesc = require('BaseSystem').ComponentRequirementDesc
    instance:addComponentRequirement(TransformCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))
    instance:initView()
    return instance
end

--- 遍历收集到的Transform组件，按父子关系更新世界变换
---@param deltaTime number
function TransformUpdateSys:tick(deltaTime)
    MOD_BaseSystem.tick(self, deltaTime)
    
    local view = self:getComponentsView()
    -- CHANGE: Use ComponentTypeName instead of ComponentTypeID
    local transforms = view._components[TransformCMP.ComponentTypeName]
    
    if not transforms then return end
    
    local count = view._count
    for i = 1, count do
        ---@type TransformCMP
        local transform = transforms[i]
        if transform ~= nil then
            -- TransformCMP 内部逻辑保证了：如果需要更新，它会先递归确保父节点更新完毕。
            transform:updateTransforms()
        end
    end
end

return {
    TransformUpdateSys = TransformUpdateSys,
}
