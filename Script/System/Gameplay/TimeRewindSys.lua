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
    -- Collect all entities that have a Transform.
    if entity:getComponent_const('TransformCMP') then
        table.insert(self._rewindEntities, entity)
    end
end

function TimeRewindSys:getIsRewinding()
    return self._isRewinding or false
end

function TimeRewindSys:tick(deltaTime)
    -- Handle Input
    local requestRewind = love.keyboard.isDown('backspace')
    
    if requestRewind and not self._isRewinding then
        -- Start rewinding
        self._isRewinding = true
    elseif not requestRewind and self._isRewinding then
        -- Stop rewinding - Truncate history to current time (overwrite future)
        self._isRewinding = false
        self:truncateHistory()
    end

    if self._isRewinding then
        self:rewind(deltaTime)
    else
        self:record(deltaTime)
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
    
    
    -- Also check for Physic bodies to sync velocity if needed at the exact moment
    -- But since we are interpolating Transform, Physics body sync (position) happens in syncPhysicsBodies later.
    -- Velocity restoration:
    -- We should probably restore velocity from snapshotA to respect continuity?
    -- Interpolating velocity is also possible if supported.
    for entity, entitySnapshotA in pairs(snapshotA.data) do
         local physic = entity:getComponent('PhysicCMP')
         if physic and physic.restoreRewindState then
             -- Just restore discrete velocity from A to avoid weird physics interpolation issues?
             -- Or lerp? PhysicCMP doesn't implement lerp yet, falls back to restore.
             if physic.lerpRewindState then
                  local entitySnapshotB = snapshotB.data[entity]
                  if entitySnapshotB and entitySnapshotB[physic:getTypeID()] then
                      physic:lerpRewindState(entitySnapshotA[physic:getTypeID()], entitySnapshotB[physic:getTypeID()], t)
                  else
                      physic:restoreRewindState(entitySnapshotA[physic:getTypeID()])
                  end
             else
                  physic:restoreRewindState(entitySnapshotA[physic:getTypeID()])
             end
         end
    end
    
end

--- Force sync physics bodies to current transform (World)
--- Call this after TransformUpdateSys has updated world matrices during rewind
function TimeRewindSys:syncPhysicsBodies()
    for _, entity in ipairs(self._rewindEntities) do
        local physic = entity:getComponent('PhysicCMP')
        local transform = entity:getComponent_const('TransformCMP')
        if physic and transform and physic.syncBodyFromTransform then
            physic:syncBodyFromTransform(transform)
        end
    end
end

return { TimeRewindSys = TimeRewindSys }
