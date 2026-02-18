
local MOD_BaseSystem = require('BaseSystem').BaseSystem
local DrawableCMP = require('Component.DrawableCMP').DrawableCMP
local TransformCMP = require('Component.TransformCMP').TransformCMP

---@class DisplaySys : BaseSystem
local DisplaySys = setmetatable({}, MOD_BaseSystem)
DisplaySys.__index = DisplaySys
DisplaySys.SystemTypeName = "DisplaySys"


function DisplaySys:new(world)
    local instance = setmetatable(MOD_BaseSystem.new(self, DisplaySys.SystemTypeName, world), self)
    local ComponentRequirementDesc = require('BaseSystem').ComponentRequirementDesc
    instance:addComponentRequirement(DrawableCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))
    instance:addComponentRequirement(TransformCMP.ComponentTypeID, ComponentRequirementDesc:new(true, true))
    instance:initView()
    return instance
end

function DisplaySys:tick(deltaTime)
    MOD_BaseSystem.tick(self, deltaTime)
    
    local view = self:getComponentsView()
    -- CHANGE: Use ComponentTypeName instead of ComponentTypeID
    local drawables = view._components[DrawableCMP.ComponentTypeName]
    if not drawables then return end
    
    local count = view._count
    for i = 1, count do
        ---@type AnimationCMP|nil
        local aniCmp = drawables[i]
        if aniCmp ~= nil then
            aniCmp:update(deltaTime)
        end
    end
end

function DisplaySys:draw()
    MOD_BaseSystem.draw(self)
    
    local view = self:getComponentsView()
    local drawables = view._components[DrawableCMP.ComponentTypeName]
    local transforms = view._components[TransformCMP.ComponentTypeName]
    
    if not drawables or not transforms then return end
    
    local count = view._count
    if count == 0 then return end
    
    local drawCallCount = 0
    -- 对DrawableCMP组件按照layer进行排序，layer数值越大越靠前
    -- 注意，排序的同时也需要对TransformCMP组件进行相同的排序
    local pairedList = {}
    for i = 1, count do
        table.insert(pairedList, {
            ---@type DrawableCMP
            drawable = drawables[i],
            ---@type TransformCMP
            transform = transforms[i],
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
