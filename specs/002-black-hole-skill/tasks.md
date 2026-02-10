# Tasks: Black Hole Skill

**Feature Branch**: `002-black-hole-skill`
**Feature Spec**: [spec.md](spec.md)

## Phase 1: Setup

- [x] T001 Create `GravitationalFieldCMP` data structure in `Script/Component/Gameplay/GravitationalFieldCMP.lua`
- [x] T002 Create `LifeTimeCMP` data structure in `Script/Component/Gameplay/LifeTimeCMP.lua`
- [x] T002b Fix inheritance syntax in `GravitationalFieldCMP.lua` and `LifeTimeCMP.lua` (Replace `subclass` with Lua table pattern)

## Phase 2: Foundational

- [x] T003 Create `BlackHoleSys` skeleton in `Script/System/Gameplay/BlackHoleSys.lua`
- [x] T004 Register new components and system in `Script/Config.lua`
- [x] T005 Update Architecture Documents:
    - Add `GravitationalFieldCMP` and `LifeTimeCMP` to `.specify/memory/architecture-components.md`
    - Add `BlackHoleSys` to `.specify/memory/architecture-systems.md`
    - Create component docs in `.specify/memory/components/`
    - Create system docs in `.specify/memory/systems/`

## Phase 3: User Story 1 - Activate Black Hole

**Goal**: Player can press 'T' to spawn a Black Hole entity at offset position which lasts 10s.

- [x] T006 [US1] Implement input listening for 'T' key in `BlackHoleSys` (referencing `love.keyboard.isDown` or similar) in `Script/System/Gameplay/BlackHoleSys.lua`
- [x] T007 [US1] Implement `spawnBlackHole` function to create entity with `TransformCMP`, `GravitationalFieldCMP`, `LifeTimeCMP` in `Script/System/Gameplay/BlackHoleSys.lua`
- [x] T008 [US1] Implement lifetime countdown logic to destroy entity after duration in `Script/System/Gameplay/BlackHoleSys.lua`
- [x] T009 [US1] Add `DebugColorCircleCMP` to spawned entity for visualization in `Script/System/Gameplay/BlackHoleSys.lua`

## Phase 4: User Story 2 - Gravitational Pull

**Goal**: Black Hole applies force to nearby physics objects.

- [x] T010 [US2] Implement physics entity query logic (iterating through `PhysicCMP` collected entities) in `Script/System/Gameplay/BlackHoleSys.lua`
- [x] T011 [US2] Implement Inverse Square law force calculation in `Script/System/Gameplay/BlackHoleSys.lua`
- [x] T012 [US2] Apply calculated force to eligible physics bodies in `Script/System/Gameplay/BlackHoleSys.lua`

## Dependencies

- US1 must be completed before US2 (Spawning required before attraction).

## Parallel Execution
- T001 and T002 can be done in parallel.
- T006 and T007 are sequential within `BlackHoleSys`.

## Implementation Strategy
-   **MVP**: Spawn a static circle when pressing 'T' that disappears after 10s.
-   **Full**: Add physics forces to that circle.

## Phase 5: Refinement & Bug Fixes

- [x] T013 Fix runtime error: `attempt to call method 'getPosition_const' (a nil value)` in `BlackHoleSys.lua` (Replace with `getTranslate_const`)
- [x] T014 Add ignore list support to `GravitationalFieldCMP`
- [x] T015 Update `BlackHoleSys` to ignore "Owner" (player) and other filtered entities
- [x] T016 Implement "Trapping" mechanism in `BlackHoleSys` using stateless drag force `F = -v*k` (avoids `LinearDamping` state persistence bugs)
- [x] T017 Tune Physics Parameters (Strength 1000 -> 400)
- [x] T019 Implement Time Rewind Protocol in `LifeTimeCMP` (`getRewindState`/`restoreRewindState`)
- [x] T020 Implement Time Rewind Protocol in `GravitationalFieldCMP` (optional state)
- [x] T021 Update `BlackHoleSys` to support entity persistence (replace destroy with dormancy/resurrection logic) to allow rewinding back to life.
- [x] T022 Verify Time Dilation scaling in `BlackHoleSys` logic.
- [x] T023 Move Black Hole configuration (Radius: 5.0, ForceStrength: 400.0, MinRadius: 0.5, Duration: 10.0) from `BlackHoleSys.lua` to `Script/Config.lua`
- [x] T024 Move Black Hole Input Binding (TriggerKey: 't') from `BlackHoleSys.lua` to `Script/Config.lua`
- [x] T018 Test and Verify revisions

