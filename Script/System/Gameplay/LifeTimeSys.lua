local MOD_BaseSystem = require('BaseSystem').BaseSystem
local LifeTimeCMP = require('Component.Gameplay.LifeTimeCMP').LifeTimeCMP
local TimeManager = require('TimeManager').TimeManager
local MessageCenter = require('MessageCenter').MessageCenter

---@class LifeTimeSys : BaseSystem
---@field _isRewinding boolean
local LifeTimeSys = setmetatable({}, MOD_BaseSystem)
LifeTimeSys.__index = LifeTimeSys
LifeTimeSys.SystemTypeName = "LifeTimeSys"

function LifeTimeSys:new(world)
    local instance = setmetatable(MOD_BaseSystem.new(self, LifeTimeSys.SystemTypeName, world), self)
    local ComponentRequirementDesc = require('BaseSystem').ComponentRequirementDesc
    
    instance:addComponentRequirement(LifeTimeCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))
    
    instance:initView()
    instance._isRewinding = false

    -- Subscribe to Rewind events to track state
    local TimeRewindSys = require('System.Gameplay.TimeRewindSys')
    local messageCenter = MessageCenter.static.getInstance()
    
    messageCenter:subscribe(TimeRewindSys.Event_RewindStarted, instance, LifeTimeSys.onRewindStarted, instance, 'LifeTimeSys_RewindStart')
    messageCenter:subscribe(TimeRewindSys.Event_RewindEnded, instance, LifeTimeSys.onRewindEnded, instance, 'LifeTimeSys_RewindEnd')
    
    return instance
end

function LifeTimeSys:onRewindStarted()
    self._isRewinding = true
end

function LifeTimeSys:onRewindEnded()
    self._isRewinding = false
end

function LifeTimeSys:tick(deltaTime)
    if self._isRewinding then
        return
    end

    local view = self:getComponentsView()
    local lifeCmpList = view._components[LifeTimeCMP.ComponentTypeName]
    
    if not lifeCmpList then return end
    
    local count = view._count
    local tm = TimeManager.static.getInstance()
    
    for i = 1, count do
        local lifeCmp = lifeCmpList[i]
        local entity = lifeCmp:getEntity()
        
        if entity:isEnable_const() then
            -- Get scaled delta time
            local gameDt = tm:getDeltaTime(deltaTime, entity)
            
            -- Update LifeTime
            lifeCmp:addElapsedTime(gameDt)
            
            if lifeCmp:isExpired_const() then
                self._world:removeEntity(entity)
            end
        end
    end
end

return {
    LifeTimeSys = LifeTimeSys
}
