--- 记录渲染环境相关的变量，比如当前渲染的目标画布等
--- @class RenderEnv
--- @field _cameraProj nil|love.Transform 摄像机投影矩阵
local RenderEnv = {}
RenderEnv.__index = RenderEnv

function RenderEnv:new()
    local instance = setmetatable({}, RenderEnv)
    instance._cameraProj = nil
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

return {
    RenderEnv = RenderEnv
}
