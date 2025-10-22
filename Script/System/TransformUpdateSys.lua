-- TransformUpdateSys.lua
-- 根据父子关系更新Transform组件的世界变换

local BaseSystem = require('BaseSystem')
local TransformCMP = require('Component.TransformCMP').TransformCMP

---@class TransformUpdateSys : BaseSystem
local TransformUpdateSys = setmetatable({}, BaseSystem)
TransformUpdateSys.__index = TransformUpdateSys
TransformUpdateSys.SystemTypeName = "TransformUpdateSys"

function TransformUpdateSys:new()
    local instance = setmetatable(BaseSystem.new(self, TransformUpdateSys.SystemTypeName), self)
    instance:addComponentRequirement(TransformCMP.ComponentTypeID, true)
    return instance
end

--- 遍历收集到的Transform组件，按父子关系更新世界变换
---@param deltaTime number
function TransformUpdateSys:tick(deltaTime)
    BaseSystem.tick(self, deltaTime)
    local transforms = self._collectedComponents[TransformCMP.ComponentTypeName]
    if transforms == nil then
        return
    end

    for i = 1, #transforms do
        ---@type TransformCMP
        local transform = transforms[i]
        if transform ~= nil then
            local entity = transform._entity
            ---@type TransformCMP|nil
            local parentTransform = nil
            if entity ~= nil and entity.getParent then
                local parentEntity = entity:getParent()
                if parentEntity ~= nil then
                    local rawParentTransform = parentEntity:getComponent(TransformCMP.ComponentTypeName)
                    if rawParentTransform ~= nil then
                        ---@cast rawParentTransform TransformCMP
                        parentTransform = rawParentTransform
                    end
                end
            end

            local px, py = transform:getTranslate()
            local pr = transform:getRotate()
            local psx, psy = transform:getScale()

            local wx, wy, wr, wsx, wsy
            if parentTransform ~= nil then
                ---@cast parentTransform TransformCMP
                local pwx, pwy = parentTransform:getWorldPosition()
                local pwr = parentTransform:getWorldRotate()
                local pwsx, pwsy = parentTransform:getWorldScale()
                local cosr = math.cos(pwr)
                local sinr = math.sin(pwr)
                wx = pwx + cosr * px * pwsx - sinr * py * pwsy
                wy = pwy + sinr * px * pwsx + cosr * py * pwsy
                wr = pwr + pr
                wsx = pwsx * psx
                wsy = pwsy * psy
            else
                wx, wy, wr, wsx, wsy = px, py, pr, psx, psy
            end

            -- 检查 TransformCMP 本身是否有缓存的世界偏移（EntityMovementSys 可能把偏移累积到这里）
            if type(transform.consumePendingWorldTranslate) == 'function' then
                local pdx, pdy = transform:consumePendingWorldTranslate()
                if (pdx ~= 0 and pdy ~= 0) or (pdx ~= 0) or (pdy ~= 0) then
                    wx = wx + pdx
                    wy = wy + pdy
                end
            end

            transform:_setWorldTransform(wx, wy, wr, wsx, wsy)
        end
    end
end

return {
    TransformUpdateSys = TransformUpdateSys,
}
