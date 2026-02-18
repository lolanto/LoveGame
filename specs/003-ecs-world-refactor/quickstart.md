# Quickstart: Using the New World API

## 1. Registering a System

Systems inherit from `BaseSystem`. Instead of manually iterating entities, they register requirements in `new()` and use `ComponentsView` in `tick()`.

```lua
local MOD_BaseSystem = require('BaseSystem').BaseSystem
local TransformCMP = require('Component.TransformCMP').TransformCMP
local VelocityCMP = require('Component.VelocityCMP').VelocityCMP
local SpriteCMP = require('Component.SpriteCMP').SpriteCMP

---@class MySystem : BaseSystem
local MySystem = setmetatable({}, MOD_BaseSystem)
MySystem.__index = MySystem
MySystem.SystemTypeName = "MySystem"

function MySystem:new()
    local instance = setmetatable(MOD_BaseSystem.new(self, MySystem.SystemTypeName), self)
    
    -- 1. Register Requirements (This configures the View signature)
    -- Using the existing addComponentRequirement API style, but extended for Views
    -- (Note: Actual implementation may batch these into a View request)
    local ComponentRequirementDesc = require('BaseSystem').ComponentRequirementDesc
    instance:addComponentRequirement(TransformCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false)) -- Required
    instance:addComponentRequirement(VelocityCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false)) -- Required
    instance:addComponentRequirement(SpriteCMP.ComponentTypeID, ComponentRequirementDesc:new(false, false))  -- Optional
    
    return instance
end

function MySystem:tick(deltaTime)
    MOD_BaseSystem.tick(self, deltaTime)

    -- 2. Retrieve Optimized View from World (or Cached)
    -- The World provides a view matching the System's requirements
    local world = self:getWorld() 
    local view = world:getComponentsView(self._requiredComponentInfos)

    -- 3. Iterate Optimized View (SoA)
    local transforms = view.components[TransformCMP.ComponentTypeName]
    local velocities = view.components[VelocityCMP.ComponentTypeName]
    local sprites = view.components[SpriteCMP.ComponentTypeName]
    local ComponentsView = require('ComponentsView')

    for i = 1, #view.entities do
        local entity = view.entities[i]
        local tf = transforms[i]
        local vel = velocities[i]
        local sprite = sprites[i]
        
        -- Safe optional access check (Sentinel)
        if sprite ~= ComponentsView.EMPTY then
            -- Logic here
        end
    end
end
```

## 2. Managing Entities

Do not manipulate global tables. Use `World`.

```lua
-- Spawning
local Entity = require('Entity').Entity
local e = Entity:new("MyEntity")
e:boundComponent(TransformCMP.New())
World:addEntity(e) -- Queued for next frame

-- Despawning
World:removeEntity(e) -- Queued, then RefCount checked
```

## 3. Time Rewind Integration

When taking a snapshot, ensure you hold a reference.

```lua
-- In TimeRewindSys:record(deltaTime)
function TimeRewindSys:record(deltaTime)
    -- ...
    for _, entity in ipairs(self._rewindEntities) do
        if entity:isEnable_const() then
            -- [New] Retain entity to prevent premature destruction
            entity:retain() 
            
            -- Capture state...
            -- ...
        end
    end
    -- ...
end

-- In TimeRewindSys:truncateHistory() / rewind()
-- When a snapshot is removed from history:
function TimeRewindSys:discardSnapshot(snapshot)
    for entity, entityData in pairs(snapshot.data) do
        -- [Key Change]: We key snapshots by Entity reference (as per existing sys), 
        -- but now we must release the ref count.
        entity:release() 
    end
end
```
