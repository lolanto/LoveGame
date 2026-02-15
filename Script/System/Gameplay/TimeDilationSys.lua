local MOD_BaseSystem = require('BaseSystem').BaseSystem

---@class TimeDilationSys : BaseSystem
---@field _isDilationActive boolean 慢动作是否激活
---@field _isRewindActive boolean 时间回溯是否激活
local TimeDilationSys = setmetatable({}, MOD_BaseSystem)
TimeDilationSys.__index = TimeDilationSys
TimeDilationSys.SystemTypeName = "TimeDilationSys"

function TimeDilationSys:new(world)
    local instance = setmetatable(MOD_BaseSystem.new(self, TimeDilationSys.SystemTypeName, world), self)
    instance._isDilationActive = false
    instance._timeRewindSys = nil
    instance:initView() -- Even if empty, good practice
    return instance
end

--- 设置关联的时间回溯系统，用于优先级判断
---@param timeRewindSys TimeRewindSys
function TimeDilationSys:setTimeRewindSys(timeRewindSys)
    self._timeRewindSys = timeRewindSys
end

--- 处理用户输入
--- 在用户按着Ctrl键的时候，进入慢动作状态
---@param userInteractController UserInteractController 用户交互控制器
function TimeDilationSys:processUserInput(userInteractController)
    local TimeManager = require('TimeManager').TimeManager.static.getInstance()

    -- 优先级检查：如果时间回溯激活中，强制在逻辑上退出慢动作状态，并直接返回
    -- 注意：TimeRewindSys 已经负责了将 TimeScale 重置为 1.0，所以这里只需要更新自身状态
    if self._timeRewindSys and self._timeRewindSys:getIsRewinding() then
        if self._isDilationActive then
            -- 既然回溯系统会重置时间，我们只需要更新标记
            self._isDilationActive = false
        end
        return
    end

    local _keyPressedCheckFunc = function(keyObj)
        if keyObj == nil then return false end
        local isPressed, _ = keyObj:getIsPressed()
        return isPressed
    end

    -- 检查左Ctrl或右Ctrl
    -- 注意：这里使用 tryToConsumeInteractInfo 会消耗掉输入状态。
    -- 如果有其他组合键依赖 Ctrl (如 Ctrl+S)，需要注意系统的执行顺序。
    local consumeL = {key_lctrl = require('UserInteractDesc').InteractConsumeInfo:new(_keyPressedCheckFunc)}
    local consumeR = {key_rctrl = require('UserInteractDesc').InteractConsumeInfo:new(_keyPressedCheckFunc)}
    
    local isCtrlPressed = userInteractController:tryToConsumeInteractInfo(consumeL) 
                       or userInteractController:tryToConsumeInteractInfo(consumeR)

    if isCtrlPressed then
        if not self._isDilationActive then
            self._isDilationActive = true
            TimeManager:setTimeScale(0.1)
        end
    else
        -- 只有当之前是激活状态，且现在没按下时，才恢复
        if self._isDilationActive then
            self._isDilationActive = false
            TimeManager:setTimeScale(1.0)
        end
    end
end

function TimeDilationSys:tick(deltaTime)
    MOD_BaseSystem.tick(self, deltaTime)
end

return {
    TimeDilationSys = TimeDilationSys
}
