
local MOD_BaseComponent = require('BaseComponent').BaseComponent

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
    local halfWindowWidth = love.graphics.getPixelWidth() / 2
    local halfWindowHeight = love.graphics.getPixelHeight() / 2
    -- 让镜头中心对准窗口中心
    --[[
        这段比较复杂，简单说明下实现。
        1. love2d的坐标系统单位是像素
        2. love2d的坐标系统，默认的原点在左上角，X轴向右，Y轴向下
        这个矩阵会在之后替换掉当帧的所有视口变换矩阵。比方说，假如绘制一个对象在(0,0)位置，
        在没有任何变换的情况下，这个对象会绘制在窗口的左上角。
        现在我们希望摄像机的中心在窗口的中心，那可以将绘制的位置平移到窗口中心位置，也就是(halfWindowWidth, halfWindowHeight)。
        假如我们希望所有的对象都能受相同的影响，那么，相当于我们要让当前视口变换的矩阵，就变为一个平移矩阵，将原点平移到(halfWindowWidth, halfWindowHeight)。

        因此才看到下面的newTransform，在x,y方向上平移halfWindowWidth, halfWindowHeight。
    --]]
    local proj = love.math.newTransform(halfWindowWidth, halfWindowHeight, 0, self._viewWidthScale, self._viewHeightScale)
    return proj
end

return {
    CameraCMP = CameraCMP,
}
