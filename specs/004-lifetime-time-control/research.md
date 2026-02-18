# Research: LifeTime Component Enhancement

**Status**: Complete
**Feature**: LifeTime Component Enhancement

## Executive Summary

The `LifeTimeCMP` currently exists but relies on manual updates within specific systems (e.g., `BlackHoleSys`). This approach is scalable and prone to inconsistencies, especially with Time Scale and Time Rewind features. This research confirms the need for a dedicated `LifeTimeSys` and outlines the integration strategy with `TimeManager` and `TimeRewindSys`.

## Decisions

### 1. Dedicated `LifeTimeSys`

**Decision**: Implement `LifeTimeSys` as a standard `BaseSystem` in `Script/System/Gameplay/`.
**Rationale**: Centralizing lifetime logic ensures all entities with `LifeTimeCMP` behave consistently without duplicate code in every system.
**Alternatives**:
- *Keep manual updates*: Rejected. High maintenance, risk of forgetting to update in new systems.

### 2. Time Scale Integration

**Decision**: Use `TimeManager:getDeltaTime(deltaTime, entity)` in `LifeTimeSys`.
**Rationale**: `TimeManager` encapsulates the time scaling logic (global scale and entity exceptions). Using it ensures `LifeTimeCMP` automatically respects slow motion, pause, and fast forward.

### 3. Time Rewind Strategy

**Decision**:
- `LifeTimeSys`: Updates `_elapsedTime` forward during normal execution.
- `TimeRewindSys`: Handles restoring `_elapsedTime` from history snapshots during rewind.
- **Conflict Resolution**: `LifeTimeSys` does not need special "isRewinding" checks because `TimeRewindSys` typically overrides the state *after* or *instead of* normal updates during the rewind phase (depending on engine loop). Even if `LifeTimeSys` runs, `TimeRewindSys` will overwrite the state. However, to save performance and avoid fighting, `LifeTimeSys` *should* check `TimeRewindSys:getIsRewinding()` and skip processing if true.

### 4. Component Interface

**Decision**: Keep `LifeTimeCMP` data model as is (`_maxDuration`, `_elapsedTime`). Ensure `restoreRewindState` correctly updates `_elapsedTime`.

## Open Questions Resolved

- **Q**: Does `TimeRewindSys` restore removed entities?
- **A**: Yes. `TimeRewindSys` tracks entities in history. If an entity exists in a past snapshot but not in the world, `TimeRewindSys` re-adds it. This supports the "resurrection" requirement.

- **Q**: Order of Execution?
- **A**: `LifeTimeSys` should update entities *before* `TimeRewindSys` records the frame state. This ensures the recorded state reflects the frame's progression.
