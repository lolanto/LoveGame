local MUtils = require('MUtils')
local LOG_MODULE = "InteractionManager"
MUtils.RegisterModule(LOG_MODULE)

local MessageCenterModule = require('MessageCenter')
local MessageCenter = MessageCenterModule.MessageCenter
local TimeManagerModule = require('TimeManager')
local IBroadcaster = require('EventInterfaces').IBroadcaster

---@class InteractionManager : IBroadcaster
---@field _isActive boolean
---@field _initiatorSystem table The system initiating the request (must be IBroadcaster)
---@field _timeout number
---@field _elapsed number
---@field _context table
---@field _eventStartedObject table EventObject
---@field _eventEndedObject table EventObject
local InteractionManager = setmetatable({}, IBroadcaster)
InteractionManager.__index = InteractionManager
InteractionManager.static = {}
InteractionManager.static.instance = nil

-- Define Event Constants
InteractionManager.Event_InteractionStarted = "Event_InteractionStarted"
InteractionManager.Event_InteractionEnded = "Event_InteractionEnded"

---@return InteractionManager
function InteractionManager.static.getInstance()
    if InteractionManager.static.instance == nil then
        InteractionManager.static.instance = InteractionManager:new()
    end
    return InteractionManager.static.instance
end

function InteractionManager:new()
    local instance = IBroadcaster:new("InteractionManager")
    setmetatable(instance, InteractionManager)
    instance._isActive = false
    instance._initiatorSystem = nil
    instance._timeout = 0
    instance._elapsed = 0
    instance._context = nil
    
    -- Register Events
    local mc = MessageCenter.static.getInstance()
    instance._eventStartedObject = mc:registerEvent(InteractionManager.Event_InteractionStarted)
    instance._eventEndedObject = mc:registerEvent(InteractionManager.Event_InteractionEnded)
    
    return instance
end

---Requests start of Interaction Mode
---@param system table The system initiating the request (BaseSystem)
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
    
    MUtils.Log(LOG_MODULE, "Interaction Started by " .. tostring(system and system._nameOfSystem or "Unknown"))
    
    -- Integration: Global Time Scale 0
    -- Note: TimeManager needs to support 0 scale (Task T003)
    -- TimeManagerModule.TimeManager.static.getInstance():setTimeScale(0)
    
    -- Broadcast Event
    local mc = MessageCenter.static.getInstance()
    mc:broadcast(self, self._eventStartedObject, { initiator = system, context = self._context })
    
    return true
end

---Ends the current interaction
---@param reason string "Manual", "Timeout", "Cancel"
function InteractionManager:requestEnd(reason)
    if not self._isActive then return end
    
    MUtils.Log(LOG_MODULE, "Interaction Ended: " .. (reason or "Unknown"))
    
    local system = self._initiatorSystem
    
    self._isActive = false
    self._initiatorSystem = nil
    
    -- Integration: Restore Global Time Scale
    -- TimeManagerModule.TimeManager.static.getInstance():setTimeScale(1.0)
    
    -- Broadcast Event
    local mc = MessageCenter.static.getInstance()
    mc:broadcast(self, self._eventEndedObject, { initiator = system, reason = reason })
end

---Update loop for timeout management and manual system ticking
---@param dt number Unscaled DeltaTime
---@param userInteractController table|nil Optional input controller
function InteractionManager:tick(dt, userInteractController)
    if not self._isActive then return end
    
    -- 1. Timeout Logic
    self._elapsed = self._elapsed + dt
    if self._timeout > 0 and self._elapsed >= self._timeout then
        self:requestEnd("Timeout")
        return -- End processed, stop ticking
    end
    
    -- 2. Manual System Ticking (Since World loop is paused)
    local world = require('World').World.static.getInstance()
    world:clean()
    
    -- 2.1 Initiator System (The specific skill logic)
    if self._initiatorSystem then
        -- Explicitly inject input controller if supported
        if userInteractController and type(self._initiatorSystem.processUserInput) == 'function' then
            self._initiatorSystem:processUserInput(userInteractController)
        end

        -- Check again if initiatorSystem exists (it might have ended interaction during input processing)
        if self._initiatorSystem then
            if type(self._initiatorSystem.tick_interaction) == 'function' then
                self._initiatorSystem:tick_interaction(dt)
            elseif type(self._initiatorSystem.tick) == 'function' then
                self._initiatorSystem:tick(dt)
            end
        end
    end

    -- 2.2 basic system update
    local transformUpdateSys = world:getSystem('TransformUpdateSys')
    if transformUpdateSys then transformUpdateSys:tick(dt) end

    local cameraSys = world:getSystem('CameraSetupSys')
    if cameraSys then cameraSys:tick(dt) end
    
    local displaySys = world:getSystem('DisplaySys')
    if displaySys then 
        -- DisplaySys expects unscaled delta time for rendering, but we must ensure
        -- it doesn't trigger component updates that should be paused (like Animations).
        -- However, DisplaySys.tick typically just calls draw() on components.
        -- If DisplaySys calls component:update(), we have a problem.
        -- Let's check DisplaySys. 
        -- Assuming DisplaySys only handles rendering.
        displaySys:tick(dt) 
    end
    
end

---Draws the interaction overlay and debug info
function InteractionManager:draw()
    if not self._isActive then return end
    love.graphics.origin()
    -- Overlay (50% Black)
    local w, h = love.graphics.getDimensions()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("INTERACTION MODE", w/2 - 50, 20)
end

---@return boolean
function InteractionManager:isActive()
    return self._isActive
end

return {
    InteractionManager = InteractionManager
}
