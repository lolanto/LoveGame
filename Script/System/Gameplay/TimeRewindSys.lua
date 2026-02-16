local MOD_BaseSystem = require('BaseSystem').BaseSystem
local MUtils = require('MUtils')
local ISubscriber = require('EventInterfaces').ISubscriber
local MultiInheritHelper = require('MultiInheritHelper').MultiInheritHelper

local MessageCenter = require('MessageCenter').MessageCenter
local Event_RewindStarted = MessageCenter.static.getInstance():registerEvent("Event_RewindStarted")
local Event_RewindEnded = MessageCenter.static.getInstance():registerEvent("Event_RewindEnded")

---@class TimeRewindSys : MOD_BaseSystem, ISubscriber
---@field _isRewinding boolean
---@field _history table[] -- stack of snapshots
---@field _rewindEntities Entity[]
local TimeRewindSys = MultiInheritHelper.createClass(MOD_BaseSystem, ISubscriber)
TimeRewindSys.SystemTypeName = "TimeRewindSys"

function TimeRewindSys:new(world, o)
    o = o or {}
    -- 初始化两个父类的数据
    -- BaseSystem initialization with World
    o = MOD_BaseSystem.new(self, TimeRewindSys.SystemTypeName, world)
    
    -- Mock ISubscriber initialization if needed (ISubscriber usually stateless or handles own data)
    -- Assuming MultiInheritHelper handles metatables, we just need to set properties.
    -- But since we called MOD_BaseSystem.new, we got a new table.
    -- We must ensure it behaves like TimeRewindSys which inherits ISubscriber.
    -- MultiInheritHelper.createClass already set TimeRewindSys metatable.
    
    local instance = setmetatable(o, TimeRewindSys)
    
    instance._isRewinding = false
    instance._history = {}
    instance._rewindEntities = {}
    instance._maxHistoryDuration = 10.0 -- seconds
    instance._currentRecordTime = 0
    instance._rewindSpeedMultiplier = 4.0
    
    instance:initView()

    local messageCenter = require('MessageCenter').MessageCenter.static.getInstance()

    local event_LeaveLevel = require('LevelManager').Event_LevelUnloaded
    messageCenter:subscribe(event_LeaveLevel, instance, TimeRewindSys.onLeaveLevel, instance, 'TimeRewindSys_onLeaveLevel')

    return instance
end

function TimeRewindSys:setPhysicsWorld(world)
    -- Stub compatibility
end

function TimeRewindSys:preCollect()
    self._rewindEntities = {}
end

function TimeRewindSys:collect(entity)
    if entity:getNeedRewind_const() then
        table.insert(self._rewindEntities, entity)
    end
end

function TimeRewindSys:getIsRewinding()
    return self._isRewinding or false
end

function TimeRewindSys:tick(deltaTime)
    if self._isRewinding then
        self:rewind(deltaTime)
    else
        self:record(deltaTime)
    end
end

--- 处理用户输入，决定是否启动回放功能
--- @param userInteractController UserInteractController 用户交互控制器
function TimeRewindSys:processUserInput(userInteractController)
    local _keyPressedCheckFunc = function(keyObj)
        if keyObj == nil then return false end
        local isPressed, pressingDuration = keyObj:getIsPressed()
        return isPressed
    end
    -- 判断是否MoveForward命令被触发
    local timeRewindCommandConsumeInfo = {key_backspace = require('UserInteractDesc').InteractConsumeInfo:new(_keyPressedCheckFunc)}
    if userInteractController:tryToConsumeInteractInfo(timeRewindCommandConsumeInfo) then
        self:enableRewind(true)
    else
        self:enableRewind(false)
    end
end

--- 启动是否要开启回放功能
--- @parma enable boolean 启动或者关闭回放功能
--- @return nil
function TimeRewindSys:enableRewind(enable)
    local TimeManager = require('TimeManager').TimeManager.static.getInstance()
    local messageCenter = require('MessageCenter').MessageCenter.static.getInstance()

    if enable and not self._isRewinding then
        self._isRewinding = true
        -- 进入时间回溯的瞬间，强制重置时间速率为正常值
        -- 这样可以防止回溯结束后玩家仍然处于慢动作状态，同时也明确了回溯操作本身是“打破”时间流的行为
        TimeManager:setTimeScale(1.0)
        
        messageCenter:broadcast(self, Event_RewindStarted, nil)
    elseif not enable and self._isRewinding then
        self._isRewinding = false
        self:truncateHistory()
        -- 退出回溯时，再次确保时间速率为1.0（虽然进入时已设置，但这符合"回溯结束后保持默认"的预期）
        TimeManager:setTimeScale(1.0)

        messageCenter:broadcast(self, Event_RewindEnded, nil)
    end
end

function TimeRewindSys:setRewindSpeedMultiplier(multiplier)
    self._rewindSpeedMultiplier = multiplier
end

function TimeRewindSys:record(deltaTime)
    self._currentRecordTime = self._currentRecordTime + deltaTime

    local snapshot = {}
    for _, entity in ipairs(self._rewindEntities) do
        -- Only record enabled entities
        -- If an entity is disabled, we consider it "non-existent" in the timeline,
        -- so we don't record its state. This ensures that when we rewind over this
        -- period later, the entity will be correctly disabled.
        if entity:isEnable_const() then
            local components = entity._components 
            
            local entitySnapshot = {}
            local hasData = false
            
            for typeID, component in pairs(components) do
                if component and component.getRewindState_const then
                    local state = component:getRewindState_const()
                    if state then
                        entitySnapshot[typeID] = state
                        hasData = true
                    end
                    --- 假如当前正在Debug模式，应该强制检查组件是否实现了restoreRewindState方法
                    if require('Config').Config.IS_DEBUG then
                        assert(component.restoreRewindState ~= nil, string.format("Component %s of Entity %s does not implement restoreRewindState method required for Time Rewind!", typeID, entity._name))
                    end
                end
            end
            
            if hasData then
                snapshot[entity] = entitySnapshot
                -- [Phase 3] Retain entity so it doesn't get destroyed while in history
                entity:retain()
            end
        end
    end
    
    table.insert(self._history, {
        time = self._currentRecordTime,
        data = snapshot
    })
    
    -- Cleanup old history based on duration
    while #self._history > 0 and (self._currentRecordTime - self._history[1].time > self._maxHistoryDuration) do
        local oldSnapshot = self._history[1].data
        for entity, _ in pairs(oldSnapshot) do
            entity:release()
        end
        table.remove(self._history, 1)
    end
end

function TimeRewindSys:truncateHistory()
    -- Create a new history list keeping only up to current time
    -- Since history is sorted by time
    for i = #self._history, 1, -1 do
        if self._history[i].time > self._currentRecordTime then
            local futureSnapshot = self._history[i].data
            for entity, _ in pairs(futureSnapshot) do
                entity:release()
            end
            table.remove(self._history, i)
        else
            break
        end
    end
end

function TimeRewindSys:rewind(deltaTime)
    if #self._history < 2 then
        return
    end
    
    local rewindDeltaTime = deltaTime * self._rewindSpeedMultiplier

    self._currentRecordTime = math.max(self._history[1].time, self._currentRecordTime - rewindDeltaTime)
    
    -- Find the two snapshots surrounding the current time
    -- history[i].time <= currentFuncTime < history[i+1].time
    local indexA, indexB = nil, nil
    
    -- Binary search or simple loop search from end (since we usually rewind from end)
    for i = #self._history - 1, 1, -1 do
        if self._history[i].time <= self._currentRecordTime then
            indexA = i
            indexB = i + 1
            break
        end
    end
    
    if not indexA then
        -- Out of bounds (start), clamp to first
        indexA = 1
        indexB = 1
    end
    
    local snapshotA = self._history[indexA]
    local snapshotB = self._history[indexB]
    
    local t = 0
    if snapshotB.time > snapshotA.time then
        t = (self._currentRecordTime - snapshotA.time) / (snapshotB.time - snapshotA.time)
    end
    
    -- Iterate all tracked entities to handle enable/disable state
    for _, entity in ipairs(self._rewindEntities) do
        local entitySnapshotA = snapshotA.data[entity]
        local entitySnapshotB = snapshotB.data[entity]
        
        if entitySnapshotA then
            -- Entity existed at this time: Enable it
            if entity.setEnable then entity:setEnable(true) end
            if entity.setVisible then entity:setVisible(true) end
            
            for typeID, stateA in pairs(entitySnapshotA) do
                local component = entity._components[typeID]
                local stateB = nil
                if entitySnapshotB then
                    stateB = entitySnapshotB[typeID]
                end

                if component and stateB then
                     if component.lerpRewindState then
                        component:lerpRewindState(stateA, stateB, t)
                     elseif component.restoreRewindState then
                        component:restoreRewindState(stateA)
                     end
                elseif component and component.restoreRewindState then
                     component:restoreRewindState(stateA)
                end
            end
        else
            -- Entity did not exist at this time: Disable it
            if entity.setEnable then entity:setEnable(false) end
            if entity.setVisible then entity:setVisible(false) end
        end
    end
end

function TimeRewindSys:postProcess()
    -- 物理组件的Transform属性需要在它的Transform组件都更新后，再同步回去
    -- 因为Transform组件更新过程中，子Entity的Transform会影响父Entity的Transform
    for _, entity in ipairs(self._rewindEntities) do
        local physicCMP = entity:getComponent('PhysicCMP')
        if physicCMP then
            physicCMP:syncBodyTransformFromEntityTransform()
        end
    end
end

function TimeRewindSys.onLeaveLevel(subscriberContext, broadcasterContext)
    ---@type TimeRewindSys
    local self = subscriberContext
    
    -- [Phase 3] Clear history and release all retained entities
    for _, historyItem in ipairs(self._history) do
        for entity, _ in pairs(historyItem.data) do
            entity:release()
        end
    end
    
    self._history = {}
    self._currentRecordTime = 0
end

return { 
    TimeRewindSys = TimeRewindSys,
    Event_RewindStarted = Event_RewindStarted,
    Event_RewindEnded = Event_RewindEnded
}
