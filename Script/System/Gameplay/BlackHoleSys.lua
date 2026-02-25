
local MOD_BaseSystem = require('BaseSystem').BaseSystem
local LevelManager = require('LevelManager').LevelManager
local MUtils = require('MUtils')
local Config = require('Config').Config
local GravitationalFieldCMP = require('Component.Gameplay.GravitationalFieldCMP').GravitationalFieldCMP
local LifeTimeCMP = require('Component.Gameplay.LifeTimeCMP').LifeTimeCMP
local TransformCMP = require('Component.TransformCMP').TransformCMP
local PhysicCMP = require('Component.PhysicCMP').PhysicCMP
local Geom = require('utils.geom').Geom

local InteractionManager = require('InteractionManager')
local EventInterfaces = require('EventInterfaces')

---@class BlackHoleSys : BaseSystem, ISubscriber
local BlackHoleSys = require('utils.MultiInheritHelper').MultiInheritHelper.createClass(MOD_BaseSystem, EventInterfaces.ISubscriber)
BlackHoleSys.SystemTypeName = "BlackHoleSys"

function BlackHoleSys:new(world)
    -- BaseSystem constructor
    -- Note: BaseSystem:new(name, world) uses 'self' as metatable. 
    -- Since we call it as MOD_BaseSystem.new(self, ...), 'self' is BlackHoleSys class.
    local instance = MOD_BaseSystem.new(self, BlackHoleSys.SystemTypeName, world)
    
    -- ISubscriber constructor (mixin initialization)
    -- Pass 'instance' as the object to modify. ISubscriber:new now respects existing metatables.
    EventInterfaces.ISubscriber.new(nil, BlackHoleSys.SystemTypeName, instance)
    
    local ComponentRequirementDesc = require('BaseSystem').ComponentRequirementDesc
    
    instance:addComponentRequirement(GravitationalFieldCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))
    instance:addComponentRequirement(LifeTimeCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))
    instance:addComponentRequirement(TransformCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))
    
    instance._spawnCooldown = Config.BlackHole.SpawnCooldown 
    instance._spawnRequested = false
    instance._inputCooldown = 0
    instance._indicatorEntity = nil
    instance._waitForKeyRelease = false
    
    instance:initView()
    -- Create a separate view for PhysicCMP since we need to iterate ALL physics objects against each black hole
    instance._physicsView = world:getComponentsView({
        [PhysicCMP.ComponentTypeName] = ComponentRequirementDesc:new(true, false),
        [TransformCMP.ComponentTypeName] = ComponentRequirementDesc:new(true, true) -- Need position? Or use Body position
    })
    
    -- Subscribe to InteractionEnded Event
    local mc = require('MessageCenter').MessageCenter.static.getInstance()
    local eventObj = mc:registerEvent(InteractionManager.InteractionManager.Event_InteractionEnded)
    mc:subscribe(eventObj, instance, instance.onInteractionEnded, instance, "BlackHoleSys_IntegrationListener")
    
    return instance
end

function BlackHoleSys:setMainCharacter(entity)
    self._mainCharacter = entity
end

function BlackHoleSys:tick(deltaTime)
    MOD_BaseSystem.tick(self, deltaTime)
    
    -- Interaction Mode Logic is delegated to tick_interaction via InteractionManager
    -- Standard Tick handles physics update for existing black holes
    
    -- Iterable Black Holes
    local view = self:getComponentsView()
    local gravCmpList = view._components[GravitationalFieldCMP.ComponentTypeName]
    local transCmpList = view._components[TransformCMP.ComponentTypeName]
    
    if not gravCmpList or not transCmpList then return end
    
    local count = view._count
    -- Use game time from TimeManager if needed, but here simple subtraction?
    -- Actually LifeTimeCMP needs elapsed time.
    local tm = require('TimeManager').TimeManager.static.getInstance()
    
    for i = 1, count do
        local gravCmp = gravCmpList[i]
        local transCmp = transCmpList[i]
        local entity = gravCmp:getEntity()
        
        -- Calculate gameDt for this entity
        local gameDt = tm:getDeltaTime(deltaTime, entity)
        
        if entity:isEnable_const() then
             -- Update LifeTime IS HANDLED BY LifeTimeSys NOW
             self:applyAttraction(transCmp, gravCmp, gameDt)
        end
    end
end

function BlackHoleSys:setPhysicSys(physicSys)
    self._physicSys = physicSys
end

function BlackHoleSys:processUserInput(userInteractController)
    local im = require('InteractionManager').InteractionManager.static.getInstance()
    
    -- If already in interaction mode initiated by us, handle interaction inputs
    if im:isActive() and im._initiatorSystem == self then
        self:processInteractionInput(userInteractController)
        return
    end

    local activationKey = Config.Client.Input.Interact.BlackHole.Activation or 'o'
    local inputKeyName = 'key_' .. activationKey

    -- State Check: Wait for key release preventing auto-restart
    if self._waitForKeyRelease then
        -- Check if the key is NOT pressed (i.e., released or up)
        local _keyReleasedCheckFunc = function(keyObj)
            if keyObj == nil then return true end -- If keyObj is nil, it's definitely not pressed
            local isPressed, _ = keyObj:getIsPressed()
            return not isPressed
        end
        
        -- We try to consume the "released" state. If successful, it means the key is up.
        local releaseCheckList = {
            [inputKeyName] = require('UserInteractDesc').InteractConsumeInfo:new(_keyReleasedCheckFunc)
        }
        
        if userInteractController:tryToConsumeInteractInfo(releaseCheckList) then
            self._waitForKeyRelease = false
        else
            -- Key is still pressed, wait.
            return 
        end
    end
    
    local _keyPressedCheckFunc = function(keyObj)
        if keyObj == nil then return false end
        local isPressed, _ = keyObj:getIsPressed()
        return isPressed
    end
    
    local consumeList = {
        [inputKeyName] = require('UserInteractDesc').InteractConsumeInfo:new(_keyPressedCheckFunc)
    }
    
    if userInteractController:tryToConsumeInteractInfo(consumeList) and self._inputCooldown <= 0 then
        -- Trigger Interaction Mode
        local im = require('InteractionManager').InteractionManager.static.getInstance()
        if im:requestStart(self, 10.0, {}) then -- 10s timeout
             self:createIndicator()
             self._spawnRequested = false -- Reset
        end
        self._inputCooldown = 0.5 -- Debounce
    end
    
    if self._inputCooldown > 0 then
        self._inputCooldown = self._inputCooldown - love.timer.getDelta()
    end
end

function BlackHoleSys:processInteractionInput(uic)
    if not self._indicatorEntity then return end

    local dt = love.timer.getDelta() -- Input processing usually happens frame-by-frame
    -- Note: Since processUserInput doesn't receive dt, we use love.timer.getDelta() 
    -- or assume movement happens in tick based on flags. 
    -- However, standard practice here is to apply changes directly or set flags.
    -- Given the previous code applied movement directly in tick_interaction using dt,
    -- we can do it here but we need to be careful about which dt to use (real time vs game time).
    -- InteractionMode usually uses Real Time (unscaled).
    
    -- 1. Handle Movement (WASD)
    local moveSpeed = 10.0 -- Configurable?
    local moveDir = {x = 0, y = 0}
    
    -- Helper for movement input
    local function isKeyDown(key)
        local keyObj = uic._interactStates['key_' .. key]
        if keyObj then
            local isDown, _ = keyObj:getIsPressed()
            return isDown
        end
        return false
    end
    
    local keys = Config.Client.Input.Interact.BlackHole.Movement
    if isKeyDown(keys.Up) then moveDir.y = moveDir.y - 1 end
    if isKeyDown(keys.Down) then moveDir.y = moveDir.y + 1 end
    if isKeyDown(keys.Left) then moveDir.x = moveDir.x - 1 end
    if isKeyDown(keys.Right) then moveDir.x = moveDir.x + 1 end
    
    -- Normalize
    local len = math.sqrt(moveDir.x^2 + moveDir.y^2)
    if len > 0 then
        moveDir.x = moveDir.x / len
        moveDir.y = moveDir.y / len
    end
    
    -- Update Indicator Position
    if len > 0 then
        local transCmp = self._indicatorEntity:getComponent(TransformCMP.ComponentTypeName)
        local curX, curY = transCmp:getTranslate_const()
        local nextX = curX + moveDir.x * moveSpeed * dt
        local nextY = curY + moveDir.y * moveSpeed * dt

        -- Clamp to Camera View bounds
        local margin = Config.BlackHole.Radius or 0.5
        local _, clampedX, clampedY = self._world:isWorldPointInsideCamera_const(nextX, nextY, margin)
        
        transCmp:setPosition(clampedX, clampedY)
    end
    
    -- 3. Handle Cancel (ESC)
    local cancelKey = Config.Client.Input.Interact.BlackHole.Cancel or 'escape'
    local _keyReleasedCheckFunc = function(keyObj)
        if keyObj == nil then return false end
        local isReleased, _ = keyObj:getIsReleased()
        return isReleased
    end
    
    if uic:tryToConsumeInteractInfo({ ['key_' .. cancelKey] = require('UserInteractDesc').InteractConsumeInfo:new(_keyReleasedCheckFunc) }) then
        self:cancelInteraction("User Cancel")
        return
    end
    
    -- 4. Handle Confirm (Release Activation Key 'o')
    local activationKey = Config.Client.Input.Interact.BlackHole.Activation or 'o'
    if uic:tryToConsumeInteractInfo({ ['key_' .. activationKey] = require('UserInteractDesc').InteractConsumeInfo:new(_keyReleasedCheckFunc) }) then
        self:trySpawnBlackHole()
    end
end

---------------------------------------------------------------------------------
-- Interaction Mode Delegates
---------------------------------------------------------------------------------

function BlackHoleSys:tick_interaction(dt)
    if not self._indicatorEntity then return end
    
    -- Movement and Input now handled in processInteractionInput (called via processUserInput)
    
    -- 2. Validation Checks (Continuous)
    self:updateValidationState()
end

function BlackHoleSys:createIndicator()
    local mainCharacter = self._world:getMainCharacter()
    local startX, startY = 0, 0
    if mainCharacter then
        local trans = mainCharacter:getComponent(TransformCMP.ComponentTypeName)
        if trans then startX, startY = trans:getTranslate_const() end
    end
    
    -- Create Indicator Entity
    local MOD_Entity = require('Entity')
    local indicator = MOD_Entity:new('BlackHoleIndicator')
    
    local transCmp = TransformCMP:new()
    transCmp:setPosition(startX, startY)
    indicator:boundComponent(transCmp)
    
    -- Valid/Invalid Visuals
    local color = {0, 1, 0, 0.5} -- Valid green
    indicator:boundComponent(require('Component.DrawableComponents.DebugColorCircleCMP').DebugColorCircleCMP:new(color, Config.BlackHole.Radius))
    
    -- Trigger for overlap check
    -- Using Kinematic Body for Trigger? Or just TriggerCMP?
    -- TriggerCMP usually requires PhysicCMP.
    local PhysicCMP = require('Component.PhysicCMP').PhysicCMP
    local Shape = require('Component.PhysicCMP').Shape
    local physicSys = self._world:getSystem('PhysicSys')
    
    if physicSys then
        local physicsWorld = physicSys:getPhysicsWorld()
        local shapeObj = Shape.static.Circle(Config.BlackHole.Radius, 0, 0, 1)
        
        local opts = {
            bodyType = 'kinematic',
            shape = shapeObj
        }
        
        local phyCmp = PhysicCMP:new(physicsWorld, opts)
        if phyCmp._fixture then
            phyCmp._fixture:setSensor(true)
        end
        indicator:boundComponent(phyCmp)
    end
    
    local TriggerCMP = require('Component.Gameplay.TriggerCMP').TriggerCMP
    local triggerCmp = TriggerCMP:new()
    
    -- Interaction Validation Callback
    self._validationOverlapCount = 0
    
    local callback = function(selfEntity, otherEntity, eventType)
        -- Check if otherEntity is Static (Environment)
        local otherPhysicCmp = otherEntity:getComponent('PhysicCMP')
        if otherPhysicCmp and otherPhysicCmp:getBodyType_const() == 'static' then
            if eventType == 'begin' then
                self._validationOverlapCount = self._validationOverlapCount + 1
            elseif eventType == 'end' then
                 self._validationOverlapCount = self._validationOverlapCount - 1
            end
            
            -- Keep count safe
            if self._validationOverlapCount < 0 then self._validationOverlapCount = 0 end
        end
    end
    triggerCmp:setCallback(callback)
    
    indicator:boundComponent(triggerCmp)
    
    indicator:setEnable(true)
    indicator:setVisible(true)
    
    LevelManager.static.getInstance():spawnEntity(indicator)
    self._indicatorEntity = indicator
end

function BlackHoleSys:updateValidationState()
    if not self._indicatorEntity then return end

    local unpackValues = table.unpack or unpack

    local indicatorTransform = self._indicatorEntity:getComponent(TransformCMP.ComponentTypeName)
    if not indicatorTransform then return end

    local indicatorX, indicatorY = indicatorTransform:getTranslate_const()
    local indicatorRadius = Config.BlackHole.Radius or 0.5
    local minX = indicatorX - indicatorRadius
    local minY = indicatorY - indicatorRadius
    local maxX = indicatorX + indicatorRadius
    local maxY = indicatorY + indicatorRadius

    local isValid = true
    local physicSys = self._physicSys or self._world:getSystem('PhysicSys')

    if physicSys and physicSys.getPhysicsWorld then
        local physicsWorld = physicSys:getPhysicsWorld()
        if physicsWorld and physicsWorld.queryBoundingBox then
            physicsWorld:queryBoundingBox(minX, minY, maxX, maxY, function(fixture)
                if not fixture then return true end

                local body = fixture:getBody()
                if not body then return true end

                local ownerEntity = fixture:getUserData() or body:getUserData()
                if not ownerEntity or ownerEntity == self._indicatorEntity then return true end
                if not ownerEntity.getComponent then return true end

                local ownerPhysicCmp = ownerEntity:getComponent(PhysicCMP.ComponentTypeName)
                if not ownerPhysicCmp or ownerPhysicCmp:getBodyType_const() ~= 'static' then
                    return true
                end

                local shape = fixture:getShape()
                if not shape then return true end

                local intersects = false
                if shape.typeOf and shape:typeOf("CircleShape") then
                    local localX, localY = shape:getPoint()
                    local worldX, worldY = body:getWorldPoint(localX, localY)
                    intersects = Geom.circleVsCircle(indicatorX, indicatorY, indicatorRadius, worldX, worldY, shape:getRadius())
                elseif shape.typeOf and shape:typeOf("PolygonShape") then
                    local localPoints = { shape:getPoints() }
                    if #localPoints >= 6 then
                        local worldPoints = { body:getWorldPoints(unpackValues(localPoints)) }
                        intersects = Geom.circleVsPolygon(indicatorX, indicatorY, indicatorRadius, worldPoints)
                    end
                else
                    local success, boxMinX, boxMinY, boxMaxX, boxMaxY = pcall(function()
                        return fixture:getBoundingBox(1)
                    end)
                    if success then
                        intersects = Geom.circleVsAabb(indicatorX, indicatorY, indicatorRadius, boxMinX, boxMinY, boxMaxX, boxMaxY)
                    end
                end

                if intersects then
                    isValid = false
                    return false
                end

                return true
            end)
        end
    end
    
    -- Visual Feedback
    -- Green if valid, Red if invalid
    local color = isValid and {0, 1, 0, 0.4} or {1, 0, 0, 0.4}
    local drawCmp = self._indicatorEntity:getComponent('DebugColorCircleCMP')
    if drawCmp then drawCmp:setColor(color) end
    
    self._isValidPlacement = isValid
end

---@param context table The listener context (self)
---@param args table Event arguments { initiator = system, reason = reason }
function BlackHoleSys.onInteractionEnded(context, args)
    local self = context
    -- Check if this interaction was initiated by us
    if args and args.initiator == self then
        if self._indicatorEntity then
            self._world:removeEntity(self._indicatorEntity)
            self._indicatorEntity = nil
        end
        -- Interaction ended, forbid immediate restart until key release
        self._waitForKeyRelease = true
    end
end

function BlackHoleSys:cancelInteraction(reason)
    -- Just enable the end request, cleanup happens in onInteractionEnded
    require('InteractionManager').InteractionManager.static.getInstance():requestEnd(reason)
end

function BlackHoleSys:trySpawnBlackHole()
    if not self._isValidPlacement then 
        -- self:cancelInteraction("Invalid Placement") -- Or just play sound?
        return 
    end
    
    local transCmp = self._indicatorEntity:getComponent(TransformCMP.ComponentTypeName)
    local x, y = transCmp:getTranslate_const()
    
    self:spawnBlackHoleAt(x, y)
    self:cancelInteraction("Spawned")
end

function BlackHoleSys:spawnBlackHoleAt(x, y)
    local MOD_Entity = require('Entity')
    local bhEntity = MOD_Entity:new('BlackHole')
    
    local bhTransCmp = TransformCMP:new()
    bhTransCmp:setPosition(x, y)
    bhEntity:boundComponent(bhTransCmp)
    
    local gravLimitCmp = GravitationalFieldCMP:new(Config.BlackHole.Radius, Config.BlackHole.ForceStrength, Config.BlackHole.MinRadius)
    -- Ignore Main Character
    local mainChar = self._mainCharacter or self._world:getMainCharacter()
    if mainChar then 
        gravLimitCmp:addIgnoreEntity(mainChar) 
    end
    
    bhEntity:boundComponent(gravLimitCmp)
    bhEntity:boundComponent(LifeTimeCMP:new(Config.BlackHole.Duration))
    bhEntity:boundComponent(require('Component.DrawableComponents.DebugColorCircleCMP').DebugColorCircleCMP:new(Config.BlackHole.DebugColor, Config.BlackHole.Radius))
    
    bhEntity:setNeedRewind(true)
    bhEntity:setEnable(true)
    bhEntity:setVisible(true)
    LevelManager.static.getInstance():spawnEntity(bhEntity)
end

function BlackHoleSys:applyAttraction(bhTrans, gravCmp, dt)
    local physics = self._physicsView._components[PhysicCMP.ComponentTypeName]
    local pCount = self._physicsView._count
    
    if not physics or pCount == 0 then return end
    
    local bhX, bhY = bhTrans:getTranslate_const()
    local radius = gravCmp:getRadius_const()
    local radiusSq = radius * radius
    local minRadius = gravCmp:getMinRadius_const()
    local forceStr = gravCmp:getForceStrength_const()
    
    for i = 1, pCount do
        local pCmp = physics[i]
        local targetEntity = pCmp:getEntity_const()
        
        -- Skip self, ignored entities, and static bodies
        if pCmp and pCmp:getBodyType_const() == 'dynamic' and targetEntity and not gravCmp:isIgnored_const(targetEntity) then
             local tx, ty = pCmp:getBodyPosition_const()
             
             local dx = bhX - tx
             local dy = bhY - ty
             local distSq = dx*dx + dy*dy
             
             if distSq < radiusSq then
                 local dist = math.sqrt(distSq)
                 local effectiveDist = math.max(dist, minRadius)
                 
                 local vx, vy = pCmp:getLinearVelocity_const()
                 local mass = pCmp:getMass_const()
                 local simulatedDamping = 0.0
                 
                 if dist < minRadius then
                     -- Trapping Zone: High Damping
                     simulatedDamping = 20.0
                 else
                     -- Attraction Zone: 
                     -- We apply a small amount of damping to stabilize orbiting objects
                     -- and prevent them from accelerating infinitely
                     simulatedDamping = 1.0 
                     
                     -- Inverse Square Law: F = (Strength * Mass) / r^2
                     -- Start with mass-independent acceleration (Strength / r^2) then mul by mass for F=ma
                     local acceleration = forceStr / (effectiveDist * effectiveDist)
                     local forceMagnitude = acceleration * mass
                     
                     local dirX, dirY = dx/dist, dy/dist
                     pCmp:applyForce(dirX * forceMagnitude, dirY * forceMagnitude)
                 end
                 
                 if simulatedDamping > 0 then
                     -- Apply drag force
                     local dragForceX = -vx * mass * simulatedDamping
                     local dragForceY = -vy * mass * simulatedDamping
                     pCmp:applyForce(dragForceX, dragForceY)
                 end
             end
        end
    end
end

return {
    BlackHoleSys = BlackHoleSys
}
