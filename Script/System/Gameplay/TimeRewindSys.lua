local BaseSystem = require('BaseSystem').BaseSystem

---@class TimeRewindSys : BaseSystem
---@field _isRewinding boolean
---@field _history table[] -- stack of snapshots
---@field _rewindEntities Entity[]
local TimeRewindSys = setmetatable({}, {__index = BaseSystem})
TimeRewindSys.__index = TimeRewindSys
TimeRewindSys.SystemTypeName = "TimeRewindSys"

function TimeRewindSys:new()
    local instance = setmetatable(BaseSystem.new(self, TimeRewindSys.SystemTypeName), self)
    instance._isRewinding = false
    instance._history = {}
    instance._rewindEntities = {}
    instance._maxHistoryDuration = 10.0 -- seconds
    instance._currentRecordTime = 0
    return instance
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
    if enable and not self._isRewinding then
        self._isRewinding = true
    elseif not enable and self._isRewinding then
        self._isRewinding = false
        self:truncateHistory()
    end
end

function TimeRewindSys:record(deltaTime)
    self._currentRecordTime = self._currentRecordTime + deltaTime

    local snapshot = {}
    for _, entity in ipairs(self._rewindEntities) do
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
        end
    end
    
    table.insert(self._history, {
        time = self._currentRecordTime,
        data = snapshot
    })
    
    -- Cleanup old history based on duration
    while #self._history > 0 and (self._currentRecordTime - self._history[1].time > self._maxHistoryDuration) do
        table.remove(self._history, 1)
    end
end

function TimeRewindSys:truncateHistory()
    -- Create a new history list keeping only up to current time
    -- Since history is sorted by time
    for i = #self._history, 1, -1 do
        if self._history[i].time > self._currentRecordTime then
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
    
    self._currentRecordTime = math.max(self._history[1].time, self._currentRecordTime - deltaTime)
    
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
    
    -- Iterate all entities in A (or B? Union ideally)
    -- For simplicity, interpolate entities present in A.
    for entity, entitySnapshotA in pairs(snapshotA.data) do
        local entitySnapshotB = snapshotB.data[entity]
        
        -- If entity existed in both frames interpolate
        if entitySnapshotB then
            for typeID, stateA in pairs(entitySnapshotA) do
                local component = entity._components[typeID]
                local stateB = entitySnapshotB[typeID]
                
                if component and stateB then
                     if component.lerpRewindState then
                        component:lerpRewindState(stateA, stateB, t)
                     elseif component.restoreRewindState then
                        component:restoreRewindState(stateA)
                     end
                elseif component and component.restoreRewindState then
                     -- B missing, fallback to A
                     component:restoreRewindState(stateA)
                end
            end
        else
            -- Entity in A but not B? Restore A
             for typeID, stateA in pairs(entitySnapshotA) do
                local component = entity._components[typeID]
                if component and component.restoreRewindState then
                    component:restoreRewindState(stateA)
                end
             end
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

return { TimeRewindSys = TimeRewindSys }
