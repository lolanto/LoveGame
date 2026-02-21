local MUtils = require('MUtils')
local LOG_MODULE = "InteractionManager"
MUtils.RegisterModule(LOG_MODULE)

---@class InteractionManager
---@field _isActive boolean
---@field _initiatorSystem BaseSystem
---@field _timeout number
---@field _elapsed number
---@field _context table
---@field _eventBroadcast table EventObject
local InteractionManager = {}
InteractionManager.__index = InteractionManager
InteractionManager.static = {}
InteractionManager.static.instance = nil

---@return InteractionManager
function InteractionManager.static.getInstance()
    if InteractionManager.static.instance == nil then
        InteractionManager.static.instance = InteractionManager:new()
    end
    return InteractionManager.static.instance
end

function InteractionManager:new()
    local instance = setmetatable({}, InteractionManager)
    instance._isActive = false
    instance._initiatorSystem = nil
    instance._timeout = 0
    instance._elapsed = 0
    instance._context = nil
    
    -- Event Initialization (Example)
    -- instance._eventBroadcast = MessageCenter.getEvent(InteractionStarted)
    
    return instance
end

---Requests start of Interaction Mode
---@param system BaseSystem The system initiating the request
---@param timeout number Max duration in seconds
---@param context table Additional data
---@return boolean Success
function InteractionManager:requestStart(system, timeout, context)
    if self._isActive then
        MUtils.Log(LOG_MODULE, "Request denied: Interaction already active")
        return false
    end
    
    self._isActive = true
    self._initiatorSystem = system
    self._timeout = timeout or 5
    self._elapsed = 0
    self._context = context or {}
    
    MUtils.Log(LOG_MODULE, "Interaction Started by " .. tostring(system._nameOfSystem))
    
    -- Integration: Global Time Scale 0
    require('TimeManager').TimeManager.static.getInstance():setTimeScale(0)
    
    -- Broadcast Event
    local MessageCenter = require('MessageCenter')
    MessageCenter.Broadcast('Event_InteractionStarted', { initiator = system, context = context })
    
    return true
end

---Ends the current interaction
---@param reason string "Manual", "Timeout", "Cancel"
function InteractionManager:requestEnd(reason)
    if not self._isActive then return end
    
    MUtils.Log(LOG_MODULE, "Interaction Ended: " .. reason)
    
    local system = self._initiatorSystem
    
    self._isActive = false
    self._initiatorSystem = nil
    
    -- Integration: Restore Global Time Scale
    require('TimeManager').TimeManager.static.getInstance():setTimeScale(1.0)
    
    -- Broadcast Event
    local MessageCenter = require('MessageCenter')
    MessageCenter.Broadcast('Event_InteractionEnded', { initiator = system, reason = reason })
end

---Update loop for timeout management
---@param dt number Unscaled DeltaTime
function InteractionManager:tick(dt)
    if not self._isActive then return end
    
    self._elapsed = self._elapsed + dt
    if self._elapsed >= self._timeout then
        self:requestEnd("Timeout")
    end
end
---@return boolean
function InteractionManager:isActive()
    return self._isActive
end

return { InteractionManager = InteractionManager }
