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
- [x] T005 Update Architecture Documents (Components/Systems memory files)

## Phase 3: User Story 1 - Interaction & Placement (Refactor)

**Goal**: Player holds 'O' to aim with an Indicator, moves it with WASD, and releases to spawn.

- [x] T006 [US1] Update `Script/Config.lua` to include `Client.Input.Interact.BlackHole` key binding (Activation, Movement, Cancel) and `BlackHole` parameters
- [x] T007 [US1] Refactor `BlackHoleSys:processUserInput` to trigger `InteractionManager:requestStart` on Activation Key press. Implement `tick_interaction` for the aiming loop.
- [x] T008 [US1] Implement `BlackHoleSys:createIndicator()` to spawn an indicator entity with `TransformCMP`, `PhysicCMP` (Sensor, Type: Static/Kinematic), `TriggerCMP`, and `DebugColorCircleCMP`
- [x] T009 [US1] Implement `BlackHoleSys:tick_interaction(dt)` to move the indicator using Configurable Movement Keys (WASD) input from `UserInteractController`. Position MUST be clamped to the Current Camera Viewport (World Space, calculated via `RenderEnv`).
- [x] T010 [US1] Implement `BlackHoleSys:cancelInteraction()` to handle Configurable Cancel Key (ESC) or Timeout (>10s Real Time) via `InteractionManager:requestEnd`, destroying the indicator without spawning
- [x] T011 [US1] Implement `BlackHoleSys:trySpawnBlackHole()` on Activation Key release inside `tick_interaction` to spawn the Black Hole and call `InteractionManager:requestEnd('Spawn')`
- [x] T012 [US1] Implement Validation Logic using `TriggerCMP` callback to detect static geometry overlap, updating Indicator visual state in `BlackHoleSys`.

## Phase 4: User Story 2 - Gravitational Pull (Existing)

**Goal**: Black Hole applies force to nearby physics objects.

- [x] T013 [US2] Implement physics entity query logic (iterating through `PhysicCMP` collected entities) in `Script/System/Gameplay/BlackHoleSys.lua`
- [x] T014 [US2] Implement Inverse Square law force calculation in `Script/System/Gameplay/BlackHoleSys.lua` (`F = (Strength * Mass) / Distance^2`)
- [x] T015 [US2] Apply calculated force to eligible physics bodies in `Script/System/Gameplay/BlackHoleSys.lua`
- [x] T016 [US2] Implement "Trapping" mechanism (drag force) for objects near center

## Phase 5: Refinement & Bug Fixes

- [x] T017 Fix runtime error: `attempt to call method 'getPosition_const' (a nil value)`
- [x] T018 Add ignore list support to `GravitationalFieldCMP` and `BlackHoleSys`
- [x] T019 Implement Time Rewind Protocol in `LifeTimeCMP`
- [x] T020 Implement Time Rewind Protocol in `GravitationalFieldCMP`
- [x] T021 Update `BlackHoleSys` to support entity persistence (dormancy/resurrection)
- [x] T022 Verify Time Dilation scaling in `BlackHoleSys` logic
- [x] T023 Move Black Hole configuration to `Script/Config.lua`
- [x] T024 Move Black Hole Input Binding (TriggerKey: 't') from `BlackHoleSys.lua` to `Script/Config.lua` (Need to Update per T006)
- [x] T025 Update force calculation in `BlackHoleSys.lua` to be Mass-Independent: `F = (Strength * Mass) / Distance^2`
- [x] T026 Verify "Ignore List" filtering uses unique Entity IDs in `BlackHoleSys.lua`

## Dependencies

- US1 Refactor needs to be completed to enable the new interaction flow.
- US2 Physics logic remains largely valid but needs to ensure it applies to the *newly spawned* Black Hole entities.

## Implementation Strategy
-   **Refactor**: Modify existing `BlackHoleSys` to replace the "Instant Spawn on T" logic with the "Indicator State Machine" logic.
-   **Reuse**: Keep the `Gravity` and `Time` logic as they are already implemented and valid (T13-T23).

