# Data Model: LifeTime Component Enhancement

## Components

### `LifeTimeCMP` (Existing)

Existing component to be managed by `LifeTimeSys`.

**Fields**:
- `_maxDuration` (number): The total duration the entity should exist.
- `_elapsedTime` (number): The current accumulated time.

**Methods**:
- `new(duration)`: Constructor. **Must assert** if `duration <= 0` or `duration > 3600`.
- `addElapsedTime(dt)`: Increment elapsed time.
- `isExpired_const()`: Returns true if `_elapsedTime >= _maxDuration`.
- `getRewindState_const()`: Returns `{ elapsedTime = self._elapsedTime }`.
- `restoreRewindState(state)`: Sets `self._elapsedTime = state.elapsedTime`.

## Systems

### `LifeTimeSys` (New)

**Inherits**: `BaseSystem`

**Responsibilities**:
- Iterates all entities with `LifeTimeCMP` in `ComponentsView`.
    - **Note**: `ComponentsView` automatically handles "External Removal" and "Disabled Entities" by excluding them.
- Checks `TimeRewindSys:getIsRewinding()`. If true, returns early (do not update).
- Calculates `gameDeltaTime` using `TimeManager`.
- Calls `LifeTimeCMP:addElapsedTime(gameDeltaTime)`.
- If `LifeTimeCMP:isExpired_const()` is true:
    - Calls `World:removeEntity(entity)`.

**Dependencies**:
- `TimeManager`: For time scaling methods (`getDeltaTime`).
- `TimeRewindSys`: For `getIsRewinding()` state check.
- `World`: For `removeEntity`.

## Integration Points

### `BlackHoleSys` (Modification)

- **Remove**: Manual iteration of `LifeTimeCMP` and calls to `addElapsedTime`.
- **Retain**: `LifeTimeCMP` requirement in `BlackHoleSys` (if needed for logic other than lifetime), otherwise remove the requirement if `BlackHoleSys` doesn't use it for anything else.
    - *Note*: BlackHoleSys might still need to know *if* it's about to expire to trigger effects, but the expiration *removal* is now handled by `LifeTimeSys`. Based on current code, it only uses it for removal.
