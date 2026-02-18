
local MOD_BaseSystem = require('BaseSystem').BaseSystem
local LevelManager = require('LevelManager').LevelManager
local MUtils = require('MUtils')
local Config = require('Config').Config
local GravitationalFieldCMP = require('Component.Gameplay.GravitationalFieldCMP').GravitationalFieldCMP
local LifeTimeCMP = require('Component.Gameplay.LifeTimeCMP').LifeTimeCMP
local TransformCMP = require('Component.TransformCMP').TransformCMP
local PhysicCMP = require('Component.PhysicCMP').PhysicCMP

---@class BlackHoleSys : BaseSystem
local BlackHoleSys = setmetatable({}, MOD_BaseSystem)
BlackHoleSys.__index = BlackHoleSys
BlackHoleSys.SystemTypeName = "BlackHoleSys"

function BlackHoleSys:new(world)
    local instance = setmetatable(MOD_BaseSystem.new(self, BlackHoleSys.SystemTypeName, world), self)
    local ComponentRequirementDesc = require('BaseSystem').ComponentRequirementDesc
    
    instance:addComponentRequirement(GravitationalFieldCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))
    instance:addComponentRequirement(LifeTimeCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))
    instance:addComponentRequirement(TransformCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))
    
    instance._spawnCooldown = Config.BlackHole.SpawnCooldown 
    instance._spawnRequested = false
    instance._inputCooldown = 0
    instance._spawnOffset = Config.BlackHole.SpawnOffset
    
    instance:initView()
    -- Create a separate view for PhysicCMP since we need to iterate ALL physics objects against each black hole
    instance._physicsView = world:getComponentsView({
        [PhysicCMP.ComponentTypeName] = ComponentRequirementDesc:new(true, false),
        [TransformCMP.ComponentTypeName] = ComponentRequirementDesc:new(true, true) -- Need position? Or use Body position
    })
    
    return instance
end

function BlackHoleSys:setupPhysicSys(sys)
    -- Deprecated in favor of self-managed view
end

function BlackHoleSys:setMainCharacter(entity)
    self._mainCharacter = entity
end

function BlackHoleSys:tick(deltaTime)
    MOD_BaseSystem.tick(self, deltaTime)
    
    if self._spawnRequested then
        self:spawnBlackHole()
        self._spawnRequested = false
    end
    
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

function BlackHoleSys:setMainCharacter(entity)
    self._mainCharacter = entity
end

function BlackHoleSys:processUserInput(userInteractController)
    local _keyPressedCheckFunc = function(keyObj)
        if keyObj == nil then return false end
        local isPressed, _ = keyObj:getIsPressed()
        return isPressed
    end

    -- Check for 'T' key press using UserInteractController
    local consumeList = {
        key_t = require('UserInteractDesc').InteractConsumeInfo:new(_keyPressedCheckFunc)
    }
    
    if userInteractController:tryToConsumeInteractInfo(consumeList) and self._inputCooldown <= 0 then
        self._spawnRequested = true
        self._inputCooldown = self._spawnCooldown
    end
    
    if self._inputCooldown > 0 then
        self._inputCooldown = self._inputCooldown - love.timer.getDelta() -- Use real time for input CD?
    end
end

-- Removed duplicate tick

function BlackHoleSys:spawnBlackHole()
    local mainCharacter = self._world:getMainCharacter()
    if not mainCharacter then return end
    
    local transCmp = mainCharacter:getComponent('TransformCMP')
    if not transCmp then return end
    
    local x, y = transCmp:getTranslate_const()
    local spawnX = x + self._spawnOffset.x
    local spawnY = y + self._spawnOffset.y
    
    local MOD_Entity = require('Entity')
    local bhEntity = MOD_Entity:new('BlackHole')
    
    local bhTransCmp = TransformCMP:new()
    bhTransCmp:setPosition(spawnX, spawnY)
    bhEntity:boundComponent(bhTransCmp)
    
    local gravLimitCmp = GravitationalFieldCMP:new(Config.BlackHole.Radius, Config.BlackHole.ForceStrength, Config.BlackHole.MinRadius)
    gravLimitCmp:addIgnoreEntity(mainCharacter)
    bhEntity:boundComponent(gravLimitCmp)
    bhEntity:boundComponent(LifeTimeCMP:new(Config.BlackHole.Duration))
    -- 使用半透明黑色表示黑洞
    bhEntity:boundComponent(require('Component.DrawableComponents.DebugColorCircleCMP').DebugColorCircleCMP:new(Config.BlackHole.DebugColor, Config.BlackHole.Radius))
    
    bhEntity:setNeedRewind(true)
    bhEntity:setEnable(true)
    bhEntity:setVisible(true)
    LevelManager.static.getInstance():spawnEntity(bhEntity)
    MUtils.Log("BlackHoleSys", "Spawned Black Hole at " .. spawnX .. ", " .. spawnY)
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
