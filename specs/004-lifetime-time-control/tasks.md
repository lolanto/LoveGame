# Tasks: LifeTime Component Enhancement

**Status**: In Progress
**Feature**: LifeTime Component Enhancement
**Branch**: `004-lifetime-time-control`

## Phase 1: Foundational (Blocking Prerequisites)

**Goal**: Establish the core system structure and robust component validation.

- [x] T001 Open `Script/Component/Gameplay/LifeTimeCMP.lua` and add assertions to `new(duration)`.
    - Assert `duration > 0` ("Duration must be positive")
    - Assert `duration <= 3600` ("Duration must be <= 1 hour")
- [x] T002 Create `Script/System/Gameplay/LifeTimeSys.lua` with basic `BaseSystem` structure.
    - Inherit from `BaseSystem`
    - Define `SystemTypeName = "LifeTimeSys"`
    - Initialize with `ComponentsView` for `LifeTimeCMP`
- [x] T003 Register `LifeTimeSys` in the main game loops.
    - Identify registration point (likely `World:init` or `main.lua` system list)
    - Ensure it is registered *before* `TimeRewindSys` (if ordered list exists) or generally in `Gameplay` Systems.

## Phase 2: User Story 1 - Time-Scaled Entity Lifetime (P1)

**Goal**: Implement the core lifetime countdown logic that respects time scaling.

**User Story**: [US1] Time-Scaled Entity Lifetime
**Independent Test criteria**: Spawn entity with 5s life. Set TimeScale=0.5. Verify it lasts 10s.

- [x] T004 [US1] Implement `tick(deltaTime)` in `Script/System/Gameplay/LifeTimeSys.lua`.
    - Function should return early if `TimeRewindSys:getIsRewinding()` is true.
- [x] T005 [P] [US1] Implement time scaling logic in `LifeTimeSys:tick`.
    - Iterate `ComponentsView` entities.
    - Get scaled delta time: `local dt = TimeManager:getDeltaTime(deltaTime, entity)`
    - Call `lifeCmp:addElapsedTime(dt)`
- [x] T006 [P] [US1] Implement expiration and removal logic in `LifeTimeSys:tick`.
    - If `lifeCmp:isExpired_const()`:
    - Call `World:removeEntity(entity)`

## Phase 3: User Story 2 - Lifetime Rewind Support (P2)

**Goal**: Ensure lifetime state is correctly restored during rewind.

**User Story**: [US2] Lifetime Rewind Support
**Independent Test criteria**: Entity dies at T=5. Rewind to T=4. Entity reappears with 1s life remaining.

- [x] T007 [US2] Verify `LifeTimeCMP` implementation of `getRewindState_const` and `restoreRewindState`.
    - Ensure `_elapsedTime` is correctly saved/restored. (Already implemented, check for edge cases)
- [x] T008 [US2] Review `TimeRewindSys` usage of `LifeTimeCMP`.
    - Confirm `LifeTimeCMP` is included in rewindable component list (or automatically picked up if generic).

## Phase 4: User Story 3 - Centralized Lifetime Management (P3)

**Goal**: Refactor existing code to use the new centralized system.

**User Story**: [US3] Centralized Lifetime Management
**Independent Test criteria**: BlackHoles still expire correctly without specific logic in `BlackHoleSys`.

- [x] T009 [US3] Open `Script/System/Gameplay/BlackHoleSys.lua`.
    - Remove the manual iteration of entities to update `LifeTimeCMP`.
    - Remove `lifeCmp:addElapsedTime` calls.
- [x] T010 [US3] Clean up `BlackHoleSys` component requirements.
    - If `LifeTimeCMP` was only required for the update loop, check if the requirement can be removed (unless needed for other logic).

## Phase 5: Verification & Polish

**Goal**: Final validation of behavior and edge cases.

- [x] T013 [US1] Fix `LifeTimeSys` execution in `Script/World.lua`.
    - Retrieve `LifeTimeSys` via `self:getSystem('LifeTimeSys')`.
    - Call `lifeTimeSys:tick(dt)` in `World:update` (inside simulation block, after rewind check).
    - Ensure it is called AFTER `TimeRewindSys` collection (Snapshot > Update).
- [ ] T011 Verify Time Scaling behavior manually.
    - Set `TimeManager` scale to 0.1, 1.0, 2.0.
    - Validate entity duration matches expected real-time duration.
- [ ] T012 Verify Rewind "Resurrection".
    - Spawn entity, let expire, rewind. Verify resurrection.

## Phase 6: Documentation

**Goal**: Update architectural documentation to reflect new system and component changes.

- [x] T014 Update `architecture-components.md` and related component docs.
    - Create/Update `.specify/memory/components/lifetime-component.md` describing fields, validation (<= 1 hour), and rewind support.
    - Ensure `LifeTimeCMP` is listed in `architecture-components.md`.
- [x] T015 Update `architecture-systems.md` and related system docs.
    - Create `.specify/memory/systems/lifetime-system.md` describing `LifeTimeSys`, including time-scaling logic and execution order (after rewind collection).
    - Add `LifeTimeSys` to `architecture-systems.md`.

## Dependencies

1.  **Phase 1** must be completed before **Phase 2** (System must exist to implement logic).
2.  **Phase 2** must be completed before **Phase 3** (Scaling logic defines base behavior).
3.  **Phase 4** relies on **Phase 2** (Central system must work before removing old logic).

## Implementation Strategy

-   **MVP**: Phases 1 & 2 deliver the core value (Time-scaled lifetime).
-   **Full Feature**: Phases 3 & 4 complete the rewind support and technical debt cleanup.
