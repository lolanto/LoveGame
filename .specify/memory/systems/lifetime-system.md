# LifeTime System

**System Name**: `LifeTimeSys`
**Source**: [Script/System/Gameplay/LifeTimeSys.lua](../../../Script/System/Gameplay/LifeTimeSys.lua)
**Registered**: [Script/World.lua](../../../Script/World.lua)

## Responsibility

The `LifeTimeSys` is a dedicated system for managing the lifespan of entities. It automatically decrements the `_elapsedTime` of any entity possessing a [LifeTimeCMP](../components/lifetime-component.md) and removes the entity from the World when its duration expires.

## Key Features

1.  **Time Scaling**:
    *   Integrates with `TimeManager` to respect global time dilation (e.g., slow motion).
    *   Calculates `gameDeltaTime` via `TimeManager:getDeltaTime(dt, entity)`.
    *   **Paused Time**: If time scale is 0, entity lifetime does not progress.

2.  **Rewind Safety**:
    *   **Passive during Rewind**: The system actively checks `TimeRewindSys:getIsRewinding()` (via event subscription or method call) and **returns early** without updating entities if a rewind is in progress.
    *   **Execution Order**: Configured in `World:update` to run **after** the `TimeRewindSys` snapshot collection phase. This ensures that the recorded state for a frame represents the entities *before* they potentially expire in that frame.

3.  **Automatic Cleanup**:
    *   Iterates all active entities with `LifeTimeCMP`.
    *   Calling `World:removeEntity(entity)` immediately upon expiration (`elapsed >= duration`).

## Dependencies

*   [LifeTimeCMP](../components/lifetime-component.md): The data component it operates on.
*   `TimeManager`: For retrieving the scaled delta time.
*   `TimeRewindSys`: To check the current rewind state (to avoid double-updating or corrupting history).

## Execution Logic

```lua
function LifeTimeSys:tick(deltaTime)
    if self._isRewinding then return end -- 1. Check Rewind State

    -- 2. Iterate Views
    for i = 1, view.count do
        -- 3. Get Scaled Time
        local dt = TimeManager:getDeltaTime(deltaTime, entity)
        
        -- 4. Update & Check
        lifeCmp:addElapsedTime(dt)
        if lifeCmp:isExpired_const() then
            self._world:removeEntity(entity)
        end
    end
end
```
