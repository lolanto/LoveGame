
local BaseSystem = require('BaseSystem')

---@class DisplaySys : BaseSystem
local DisplaySys = setmetatable({}, {__index = BaseSystem})
DisplaySys.__index = DisplaySys
DisplaySys.SystemTypeName = "DisplaySys"


function DisplaySys:new()
    local instance = setmetatable(BaseSystem.new(self, DisplaySys.SystemTypeName), self)
    instance:addComponentRequirement(require('Component.AnimationCMP').ComponentTypeID, true)
    return instance
end

function DisplaySys:tick(deltaTime)
    BaseSystem:tick()
    for i = 1, #self._collectedComponents['AnimationCMP'] do
        ---@type AnimationCMP|nil
        local aniCmp = self._collectedComponents['AnimationCMP'][i]
        if aniCmp ~= nil then
            aniCmp:update(deltaTime)
        end
    end
end

function DisplaySys:draw()
    BaseSystem:draw()
    local drawCallCount = 0
    for i = 1, #self._collectedComponents['AnimationCMP'] do
        ---@type AnimationCMP|nil
        local aniCmp = self._collectedComponents['AnimationCMP'][i]
        if aniCmp ~= nil then
            aniCmp:draw()
            drawCallCount = drawCallCount + 1
        end
    end
    assert(drawCallCount ~= 0)
end

return DisplaySys
