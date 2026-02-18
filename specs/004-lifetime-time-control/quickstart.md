# Quickstart: LifeTime Component Enhancement

## Overview

This feature introduces a centralized `LifeTimeSys` to manage entity expiration, ensuring it respects game time scaling and time rewind mechanics.

## Usage

### 1. Adding Lifetime to an Entity

When creating an entity, add the `LifeTimeCMP`:

```lua
local LifeTimeCMP = require('Component.Gameplay.LifeTimeCMP').LifeTimeCMP
local entity = Entity:new()
-- Entity will exist for 5 valuable game seconds
entity:addComponent(LifeTimeCMP:new(5.0))
world:addEntity(entity)
```

### 2. Time Scaling

The lifetime will automatically adjust to time scale:
- **Normal (1.0)**: Lasts 5 seconds.
- **Slow Motion (0.5)**: Lasts 10 real seconds (5 game seconds).
- **Fast Forward (2.0)**: Lasts 2.5 real seconds (5 game seconds).
- **Pause (0.0)**: Does not expire.

### 3. Rewind

If the entity expires and is removed, rewinding time to before its expiration will:
- Re-add the entity to the World.
- Restore its `elapsedTime` to the correct value at that moment.

## Developer Notes

- Do **NOT** manually call `addElapsedTime` in your systems. `LifeTimeSys` handles this.
- If you need to perform an action *on expiration* (death effect), currently `LifeTimeSys` just removes the entity.
- To listen for removal, you might use `World` events or Entity `onRelease` callbacks (if architecture supports).
