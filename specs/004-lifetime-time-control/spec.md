# Feature Specification: LifeTime Component Enhancement

**Feature Branch**: `004-lifetime-time-control`
**Created**: 2026-02-18
**Status**: Draft
**Input**: User description included in conversation.

## Clarifications

### Session 2026-02-18

-   Q: How should invalid durations (<=0 or >1hr) be handled? → A: Assert failure.
-   Q: How should disabled entities be handled by LifeTimeSys? → A: Excluded from processing (ComponentsView removes them).
-   Q: How to handle entities removed by other means? → A: Implicitly handled; they leave the ComponentsView and stop processing.
-   Q: Can TimeManager return negative deltaTime? → A: No, assumed positive only.
-   Q: What is the execution order relative to Rewind? → A: LifeTimeSys runs before Rewind recording; does not run during active rewind.

## User Scenarios & Testing

### User Story 1 - Time-Scaled Entity Lifetime (Priority: P1)

As a game designer, I want entities with limited lifespans to respect the global game time scale (slow motion, fast forward), so that gameplay effects remain synchronized with the visible game speed.

**Why this priority**: Core functionality for "bullet time" or time manipulation mechanics affecting transient objects like projectiles or effects.

**Acceptance Scenarios**:

1.  **Given** an entity with `LifeTimeCMP` (duration 5s) and time scale 1.0, **When** game runs for 5s real-time, **Then** entity is removed.
2.  **Given** an entity with `LifeTimeCMP` (duration 5s) and time scale 0.5, **When** game runs for 5s real-time, **Then** entity is NOT removed (elapsed game time = 2.5s).
3.  **Given** an entity with `LifeTimeCMP` (duration 5s) and time scale 2.0, **When** game runs for 2.5s real-time, **Then** entity is removed (elapsed game time = 5s).
4.  **Given** an entity with `LifeTimeCMP` and time scale 0.0 (paused), **When** game runs, **Then** entity lifetime does not decrease.

---

### User Story 2 - Lifetime Rewind Support (Priority: P2)

As a player, when I rewind time, I expect "dead" entities to reappear and their lifetime timers to revert, so that the game state accurately reflects the past.

**Why this priority**: Essential for the time-rewind mechanic to feel largely consistent and bug-free.

**Acceptance Scenarios**:

1.  **Given** an entity that expired and was removed at T=5s, **When** rewinding time from T=6s to T=4s, **Then** the entity is re-added to the World.
2.  **Given** an entity with `LifeTimeCMP`, **When** rewinding time, **Then** its `elapsedTime` decreases (restores to past values) matching the rewind timeline.
3.  **Given** an entity created at T=2s, **When** rewinding to T=1s, **Then** the entity is removed from the World (since it didn't exist yet).

---

### User Story 3 - Centralized Lifetime Management (Priority: P3)

As a developer, I want a dedicated system handling component lifecycles so I don't have to manually update `LifeTimeCMP` in every gameplay system (like BlackHoleSys).

**Why this priority**: Code refactoring to improve maintainability and reduce bugs from duplicate logic.

**Acceptance Scenarios**:

1.  **Given** a new entity with `LifeTimeCMP` but no specific gameplay system logic, **When** time passes, **Then** its lifetime processes automatically.
2.  **Given** existing code in `BlackHoleSys`, **When** refactored, **Then** it no longer calls `lifeCmp:addElapsedTime`.

---

## Functional Requirements

1.  **Dedicated Lifetime Management**:
    - The system must automatically track and update the duration of all entities with a lifetime component.
    - Entities must be removed from the simulation immediately upon expiration.
    - This management must be centralized, preventing the need for individual gameplay logic to handle lifetime decrement manually.
    - **Constraint**: `LifeTimeCMP` must assert if initialized with duration <= 0.
    - **Constraint**: `LifeTimeCMP` must assert if duration > 3600 seconds (1 hour).

2.  **Time Scale Integration**:
    - Lifetime progression must scale proportionally with the global game speed.
    - If the game is paused (time scale 0), lifetime must not decrease.
    - If the game is slowed down (e.g., 0.5x), lifetime must decrease at half speed.
    - **Assumption**: `TimeManager` handles calculation and never returns negative delta time.

3.  **Rewind Compatibility**:
    - The system must support bidirectional time flow.
    - When time is rewound, the accumulated lifetime duration must decrease (revert) to match the historical state.
    - Entities that were removed due to expiration must be capable of being restored if the timeline is rewound to a point before their expiration.
    - **Execution Logic**: `LifeTimeSys` runs *after* `TimeRewindSys` records the frame (ensuring the recorded state reflects the start of the frame).
    - **Conflict Resolution**: If `TimeRewindSys` is actively rewinding (moving backward), `LifeTimeSys` must **not** update or process entities.

4.  **Edge Cases & Lifecycle**:
    - **Disabled Entities**: Disabled entities are excluded from processing (removed from ComponentsView) and their lifetime does not progress.
    - **External Removal**: Entities removed by other means (e.g., killed) are removed from the ComponentsView and stop being processed by `LifeTimeSys`.

5.  **Refactoring existing logic**:
    - Existing specific implementations of lifetime management (e.g., in Black Hole mechanics) must be replaced by this centralized system to ensure consistency.



## Success Criteria

-   **Accuracy**: Entity lifetime duration error is within 1 simulation frame (<16ms) at various time scales.
-   **Consistency**: Rewinding restores entity state identical to the recording (position, lifetime remaining).
-   **Performance**: `LifeTimeSys` processes 1000+ entities with negligible overhead (<0.5ms).
-   **Cleanliness**: No duplicate lifetime decrement logic in other systems.

## Assumptions

-   `TimeManager` handles the global time scale and provides a corrected `deltaTime`.
-   `TimeRewindSys` is responsible for adding/removing entities and restoring component data during rewind.
-   `World:removeEntity` is safe to call from within a system iteration (the World handles pending removals).
-   Entities with `LifeTimeCMP` also have `TimeRewind` support enabled (via `getNeedRewind` or similar capability) if they need to support rewind. This is an entity configuration issue, not `LifeTimeSys` issue.

## Technical Considerations

-   **Order of Operations**: `LifeTimeSys` should run in the gameplay update phase.
-   **Dependency**: `LifeTimeSys` depends on `TimeManager`.
