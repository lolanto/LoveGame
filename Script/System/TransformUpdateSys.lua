-- TransformUpdateSys.lua
-- 根据父子关系更新Transform组件的世界变换

local MOD_BaseSystem = require('BaseSystem').BaseSystem
local TransformCMP = require('Component.TransformCMP').TransformCMP

---@class TransformUpdateSys : BaseSystem
local TransformUpdateSys = setmetatable({}, MOD_BaseSystem)
TransformUpdateSys.__index = TransformUpdateSys
TransformUpdateSys.SystemTypeName = "TransformUpdateSys"

function TransformUpdateSys:new()
    local instance = setmetatable(MOD_BaseSystem.new(self, TransformUpdateSys.SystemTypeName), self)
    local ComponentRequirementDesc = require('BaseSystem').ComponentRequirementDesc
    instance:addComponentRequirement(TransformCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))
    return instance
end

--- 遍历收集到的Transform组件，按父子关系更新世界变换
---@param deltaTime number
function TransformUpdateSys:tick(deltaTime)
    MOD_BaseSystem.tick(self, deltaTime)
    local transforms = self._collectedComponents[TransformCMP.ComponentTypeName]
    if transforms == nil then
        return
    end

    for i = 1, #transforms do
        ---@type TransformCMP
        local transform = transforms[i]
        if transform ~= nil then
            local entity = transform:getEntity()
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

            local px, py = transform:getTranslate_const()
            local pr = transform:getRotate_const()
            local psx, psy = transform:getScale_const()

            local wx, wy, wr, wsx, wsy
            if parentTransform ~= nil then
                ---@cast parentTransform TransformCMP
                local pwx, pwy = parentTransform:getWorldPosition_const()
                local pwr = parentTransform:getWorldRotate_const()
                local pwsx, pwsy = parentTransform:getWorldScale_const()
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
            local pdx, pdy = transform:consumePendingWorldTranslate()
            if (pdx ~= 0 and pdy ~= 0) or (pdx ~= 0) or (pdy ~= 0) then
                wx = wx + pdx
                wy = wy + pdy
            end

            transform:_setWorldTransform(wx, wy, wr, wsx, wsy)
            transform:updateWorldTransform()
        end
    end
end

return {
    TransformUpdateSys = TransformUpdateSys,
}
