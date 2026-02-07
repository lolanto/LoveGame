
--- 全局时间管理器
--- 负责管理全局的时间缩放比例，并处理受时间缩放影响的例外实体（如主角）
--- @class TimeManager
local TimeManager = {}
TimeManager.__index = TimeManager
TimeManager.static = {}
TimeManager.static.instance = nil

--- 获取单例
--- @return TimeManager
function TimeManager.static.getInstance()
    if TimeManager.static.instance == nil then
        TimeManager.static.instance = TimeManager:new()
    end
    return TimeManager.static.instance
end

function TimeManager:new()
    local instance = setmetatable({}, self)
    instance._globalTimeScale = 1.0
    return instance
end

--- 设置全局时间缩放比例
--- @param scale number 时间缩放比例 (e.g. 0.1 for slow motion, 1.0 for normal)
function TimeManager:setTimeScale(scale)
    assert(type(scale) == 'number' and scale > 0.0001, "Time scale must be a positive number")
    self._globalTimeScale = scale
end

--- 获取全局时间缩放比例
--- @return number
function TimeManager:getTimeScale()
    return self._globalTimeScale
end

--- 获取经过计算的DeltaTime
--- 如果实体是例外，返回原始deltaTime
--- 如果实体不是例外，返回deltaTime * scale
--- @param originalDeltaTime number 原始帧间隔
--- @param entity Entity|nil 关联的实体，如果为nil则默认应用缩放
--- @return number scaledDeltaTime
function TimeManager:getDeltaTime(originalDeltaTime, entity)
    if entity and entity:isTimeScaleException_const() then
        return originalDeltaTime
    end
    return originalDeltaTime * self._globalTimeScale
end

return {
    TimeManager = TimeManager
}
