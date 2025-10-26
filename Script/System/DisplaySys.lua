
local MOD_BaseSystem = require('BaseSystem').BaseSystem

---@class DisplaySys : BaseSystem
local DisplaySys = setmetatable({}, {__index = MOD_BaseSystem})
DisplaySys.__index = DisplaySys
DisplaySys.SystemTypeName = "DisplaySys"


function DisplaySys:new()
    local instance = setmetatable(MOD_BaseSystem.new(self, DisplaySys.SystemTypeName), self)
    local ComponentRequirementDesc = require('BaseSystem').ComponentRequirementDesc
    instance:addComponentRequirement(require('Component.DrawableCMP').DrawableCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))
    instance:addComponentRequirement(require('Component.TransformCMP').TransformCMP.ComponentTypeID, ComponentRequirementDesc:new(true, true))
    return instance
end

function DisplaySys:tick(deltaTime)
    MOD_BaseSystem:tick()
    for i = 1, #self._collectedComponents['DrawableCMP'] do
        ---@type AnimationCMP|nil
        local aniCmp = self._collectedComponents['DrawableCMP'][i]
        if aniCmp ~= nil then
            aniCmp:update(deltaTime)
        end
    end
end

function DisplaySys:draw()
    MOD_BaseSystem:draw()
    local drawCallCount = 0
    -- 对DrawableCMP组件按照layer进行排序，layer数值越大越靠前
    -- 注意，排序的同时也需要对TransformCMP组件进行相同的排序
    local pairedList = {}
    for i = 1, #self._collectedComponents['DrawableCMP'] do
        table.insert(pairedList, {
            ---@type DrawableCMP
            drawable = self._collectedComponents['DrawableCMP'][i],
            ---@type TransformCMP
            transform = self._collectedComponents['TransformCMP'][i],
        })
    end
    table.sort(pairedList, function(a, b)
        return a.drawable:getLayer() < b.drawable:getLayer()
    end)
    for i = 1, #pairedList do
        ---@type DrawableCMP
        local drawableCmp = pairedList[i].drawable
        ---@type TransformCMP
        local transformCmp = pairedList[i].transform
        drawableCmp:draw(transformCmp:getWorldTransform_const())
        drawCallCount = drawCallCount + 1
    end
end

return {
    DisplaySys = DisplaySys,
}
