local MOD_BaseSystem = require('BaseSystem').BaseSystem
local ISubscriber = require('EventInterfaces').ISubscriber
local MultiInheritHelper = require('MultiInheritHelper').MultiInheritHelper
local MessageCenter = require('MessageCenter').MessageCenter

---@class TimeDilationSys : BaseSystem, ISubscriber
---@field _isDilationActive boolean 慢动作是否激活
---@field _isRewindActive boolean 时间回溯是否激活
local TimeDilationSys = MultiInheritHelper.createClass(MOD_BaseSystem, ISubscriber)
TimeDilationSys.SystemTypeName = "TimeDilationSys"

function TimeDilationSys:new(world)
    local o = MOD_BaseSystem.new(self, TimeDilationSys.SystemTypeName, world)
    -- local instance = setmetatable(o, TimeDilationSys) -- MultiInheritHelper.createClass already sets the metatable if we use new correctly, but here we are using MOD_BaseSystem.new which returns a table with BaseSystem metatable.
    -- Actually, TimeDilationSys IS the metatable we want.
    local instance = setmetatable(o, TimeDilationSys)
    
    -- Initialize ISubscriber (Mixin style)
    ISubscriber.new(nil, "TimeDilationSys", instance)

    instance._isDilationActive = false
    instance._isRewindActive = false
    instance:initView()
    
    instance:_registerEvents()
    
    return instance
end

function TimeDilationSys:_registerEvents()
    local messageCenter = MessageCenter.static.getInstance()
    -- We need to require the module to access the Event definitions
    local TimeRewindModule = require('System.Gameplay.TimeRewindSys')
    
    messageCenter:subscribe(TimeRewindModule.Event_RewindStarted, self, self.onRewindStarted, self)
    messageCenter:subscribe(TimeRewindModule.Event_RewindEnded, self, self.onRewindEnded, self)
end

function TimeDilationSys:onRewindStarted()
    self._isRewindActive = true
    if self._isDilationActive then
        self._isDilationActive = false
        -- Time rewinds handles resetting timescale to 1.0, so we just update flag
    end
end

function TimeDilationSys:onRewindEnded()
    self._isRewindActive = false
end

--- 处理用户输入
--- 在用户按着Ctrl键的时候，进入慢动作状态
---@param userInteractController UserInteractController 用户交互控制器
function TimeDilationSys:processUserInput(userInteractController)
    local TimeManager = require('TimeManager').TimeManager.static.getInstance()

    -- 优先级检查：如果时间回溯激活中，强制在逻辑上退出慢动作状态，并直接返回
    if self._isRewindActive then
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
