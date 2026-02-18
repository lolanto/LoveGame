
local MOD_BaseSystem = require('BaseSystem').BaseSystem
local LevelManager = require('LevelManager').LevelManager
local MUtils = require('MUtils')
local Config = require('Config').Config

---@class BlackHoleSys : BaseSystem
local BlackHoleSys = setmetatable({}, MOD_BaseSystem)
BlackHoleSys.__index = BlackHoleSys
BlackHoleSys.SystemTypeName = "BlackHoleSys"

function BlackHoleSys:new()
    local instance = setmetatable(MOD_BaseSystem.new(self, BlackHoleSys.SystemTypeName), self)
    local ComponentRequirementDesc = require('BaseSystem').ComponentRequirementDesc
    
    instance:addComponentRequirement(require('Component.Gameplay.GravitationalFieldCMP').GravitationalFieldCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))
    instance:addComponentRequirement(require('Component.Gameplay.LifeTimeCMP').LifeTimeCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))
    instance:addComponentRequirement(require('Component.TransformCMP').TransformCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))
    
    instance._physicSys = nil
    instance._mainCharacter = nil
    instance._inputCooldown = 0.0
    instance._spawnCooldown = Config.BlackHole.SpawnCooldown 
    instance._spawnRequested = false
    
    -- Config
    instance._spawnOffset = Config.BlackHole.SpawnOffset
    
    return instance
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
    
    if userInteractController:tryToConsumeInteractInfo(consumeList) then
        self._spawnRequested = true
    end
end

function BlackHoleSys:tick(deltaTime)
    MOD_BaseSystem.tick(self, deltaTime)
    
    local TimeManager = require('TimeManager').TimeManager.static.getInstance()
    local scale = TimeManager:getTimeScale()
    local gameDt = deltaTime * scale

    -- 1. Input Processing
    if self._inputCooldown > 0 then
        self._inputCooldown = self._inputCooldown - deltaTime
    else
        if self._spawnRequested then
             self:spawnBlackHole()
             self._inputCooldown = self._spawnCooldown
        end
    end
    
    -- Reset spawn request to prevent buffering during cooldown
    self._spawnRequested = false
    
    local gravCmpList = self._collectedComponents['GravitationalFieldCMP']
    local lifeCmpList = self._collectedComponents['LifeTimeCMP']
    local transCmpList = self._collectedComponents['TransformCMP']
    
    if not gravCmpList then return end
    
    for i = 1, #gravCmpList do
        local gravCmp = gravCmpList[i]
        local lifeCmp = lifeCmpList[i]
        local transCmp = transCmpList[i]
        local entity = gravCmp:getEntity()
        
        -- Update LifeTime (Game Time)
        lifeCmp:addElapsedTime(gameDt)
        
        local isExpired = lifeCmp:isExpired_const()
        -- local debugCmp = entity:getComponent('DebugColorCircleCMP') -- Unused
        
        if isExpired then
             -- Hide entity instead of destroying it
             -- This allows TimeRewind to bring it back "from the dead"
             entity:setEnable(false)
             entity:setVisible(false)
             
             -- Check if it should be REALLY destroyed (e.g. expired for long time)
             -- Use 15s buffer (10s max rewind + 5s safety)
             if lifeCmp:getElapsedTime_const() > lifeCmp:getMaxDuration_const() + 15.0 then
                 entity:markForDeletion()
             end
        else
             -- Alive logic is handled by TimeRewind restoring states
             -- Just ensure normal updates
             if entity:isEnable_const() then
                 self:applyAttraction(transCmp, gravCmp, gameDt)
             end
        end
    end
end


function BlackHoleSys:spawnBlackHole()
    if not self._mainCharacter then return end
    
    local transCmp = self._mainCharacter:getComponent('TransformCMP')
    if not transCmp then return end
    
    local x, y = transCmp:getTranslate_const()
    local spawnX = x + self._spawnOffset.x
    local spawnY = y + self._spawnOffset.y
    
    local MOD_Entity = require('Entity')
    local bhEntity = MOD_Entity:new('BlackHole')
    
    local TransformCMP = require('Component.TransformCMP').TransformCMP
    local GravitationalFieldCMP = require('Component.Gameplay.GravitationalFieldCMP').GravitationalFieldCMP
    local LifeTimeCMP = require('Component.Gameplay.LifeTimeCMP').LifeTimeCMP
    local DebugColorCircleCMP = require('Component.DrawableComponents.DebugColorCircleCMP').DebugColorCircleCMP
    
    local bhTransCmp = TransformCMP:new()
    bhTransCmp:setPosition(spawnX, spawnY)
    bhEntity:boundComponent(bhTransCmp)
    
    local gravLimitCmp = GravitationalFieldCMP:new(Config.BlackHole.Radius, Config.BlackHole.ForceStrength, Config.BlackHole.MinRadius)
    gravLimitCmp:addIgnoreEntity(self._mainCharacter)
    bhEntity:boundComponent(gravLimitCmp)
    bhEntity:boundComponent(LifeTimeCMP:new(Config.BlackHole.Duration))
    -- 使用半透明黑色表示黑洞
    bhEntity:boundComponent(DebugColorCircleCMP:new(Config.BlackHole.DebugColor, Config.BlackHole.Radius))
    
    bhEntity:setNeedRewind(true)
    bhEntity:setEnable(true)
    bhEntity:setVisible(true)
    LevelManager.static.getInstance():spawnEntity(bhEntity)
    MUtils.Log("BlackHoleSys", "Spawned Black Hole at " .. spawnX .. ", " .. spawnY)
end

function BlackHoleSys:applyAttraction(bhTrans, gravCmp, dt)
    if not self._physicSys then return end
    -- Query physics entities
    local physCmps = self._physicSys._collectedComponents['PhysicCMP']
    if not physCmps then return end
    
    local bhX, bhY = bhTrans:getTranslate_const()
    local radius = gravCmp:getRadius_const()
    local forceStr = gravCmp:getForceStrength_const()
    local minRadius = gravCmp:getMinRadius_const()
    local radiusSq = radius * radius
    
    for i = 1, #physCmps do
        local pCmp = physCmps[i]
        local targetEntity = pCmp:getEntity()
        
        -- Skip self, ignored entities, and static bodies
        if pCmp and pCmp:getBodyType_const() == 'dynamic' and targetEntity and not gravCmp:isIgnored_const(targetEntity) then
             local tx, ty = pCmp:getBodyPosition_const()
             
             local dx = bhX - tx
             local dy = bhY - ty
             local distSq = dx*dx + dy*dy
             
             if distSq < radiusSq then
                 local dist = math.sqrt(distSq)
                 
                 local effectiveDist = math.max(dist, minRadius)
                 
                 -- Use Force to counteract velocity (Simulated Damping)
                 -- F = -v * m * damping
                 -- This is stateless and won't dirty the body's actual setDamping property
                 
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
                     
                     -- Inverse Square Law: F = k / r^2
                     local strength = forceStr / (effectiveDist * effectiveDist)
                     local dirX, dirY = dx/dist, dy/dist
                     pCmp:applyForce(dirX * strength, dirY * strength)
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
