
local MOD_BaseComponent = require('BaseComponent')

---@class CameraCMP : BaseComponent
---@field _viewWidthScale number
---@field _viewHeightScale number
local CameraCMP = setmetatable({}, MOD_BaseComponent)
CameraCMP.__index = CameraCMP
CameraCMP.ComponentTypeName = "CameraCMP"
CameraCMP.ComponentTypeID = MOD_BaseComponent.RegisterType(CameraCMP.ComponentTypeName)


function CameraCMP:new()
    local instance = setmetatable(MOD_BaseComponent.new(self, CameraCMP.ComponentTypeName), self)
    instance._viewWidthScale = 1.0
    instance._viewHeightScale = 1.0
    return instance
end

function CameraCMP:setViewWidthScale(widthScale)
    self._viewWidthScale = widthScale
end

function CameraCMP:setViewHeightScale(heightScale)
    self._viewHeightScale = heightScale
end

---获取当前镜头的水平和垂直缩放(平移旋转由Transform组件控制)
---@return love.Transform
function CameraCMP:getProjectionTransform()
    local proj = love.math.newTransform(0, 0, 0, self._viewWidthScale, self._viewHeightScale)
    return proj
end

return CameraCMP
