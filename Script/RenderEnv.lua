--- 记录渲染环境相关的变量，比如当前渲染的目标画布等
--- @class RenderEnv
--- @field _cameraProj nil|love.Transform 摄像机投影矩阵
--- @field _viewWidth number 视口宽度，单位米
--- @field _pixelsPerMeter number 像素每米，用来将米转换为像素
local RenderEnv = {}
RenderEnv.__index = RenderEnv
RenderEnv.static = {}
RenderEnv.static.GlobalInstance = nil

function RenderEnv.setGlobalInstance(instance)
    RenderEnv.static.GlobalInstance = instance
end

function RenderEnv.getGlobalInstance()
    return RenderEnv.static.GlobalInstance
end

function RenderEnv.getGlobalInstance_const()
    return require("utils.ReadOnly").makeReadOnly(RenderEnv.static.GlobalInstance)
end

function RenderEnv:new()
    local instance = setmetatable({}, RenderEnv)
    instance._cameraProj = nil
    instance._viewWidth = 10
    -- instance._pixelsPerMeter = love.graphics.getPixelWidth() / instance._viewWidth
    instance._pixelsPerMeter = 30  -- 默认30像素每米
    return instance
end

---设置摄像机变换矩阵
---@param cameraProj love.Transform 摄像机变换矩阵
function RenderEnv:setCameraProj(cameraProj)
    self._cameraProj = cameraProj
end

---获取摄像机变换矩阵
---@return nil|love.Transform 摄像机变换矩阵
function RenderEnv:getCameraProj()
    return self._cameraProj
end

function RenderEnv:setViewWidth(viewWidth)
    self._viewWidth = viewWidth
    -- self._pixelsPerMeter = love.graphics.getPixelWidth() / self._viewWidth
end

function RenderEnv:getViewWidth_const()
    return self._viewWidth
end

function RenderEnv:getPixelsPerMeter_const()
    return self._pixelsPerMeter
end

function RenderEnv:getMetersPerPixel_const()
    return 1 / self._pixelsPerMeter
end

function RenderEnv:pixelsToMeters_const(pixels)
    return pixels * self:getMetersPerPixel_const()
end

function RenderEnv:metersToPixels_const(meters)
    return meters * self._pixelsPerMeter
end

return {
    RenderEnv = RenderEnv
}
