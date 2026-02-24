# Tasks: Skill Interaction Mode

**Branch**: `005-skill-interaction-mode` | **Spec**: [specs/005-skill-interaction-mode/spec.md](specs/005-skill-interaction-mode/spec.md)

## Phase 1: Setup & Core Infrastructure
**Goal**: Initialize key components and data structures.

- [x] T001 Create `InteractionManager` singleton in `Script/InteractionManager.lua` following contracts
- [x] T002 Define `Event_InteractionStarted` and `Event_InteractionEnded` constants in `Script/InteractionManager.lua` and export them

## Phase 2: Foundational Logic
**Goal**: Implement the pausing mechanism and input handling (Blocking Prerequisites).

- [x] T003 Refactor `Script/World.lua`: Add `isActive()` check (via dependency injection or external flag) to skip game loop entirely when InteractionManager is active.
- [x] T004 [P] Ensure `World` exposes `getSystem` to allow manual ticking.
- [x] T005 [P] Modify `Script/UserInteractController.lua` to block standard input when InteractionManager is active
- [x] T006 Update `main.lua` to call `InteractionManager.tick(dt, userInteractController)` and `InteractionManager.draw` explicitly

## Phase 3: User Story 1 - Enter and Exit Targeting Mode
**Goal**: Enable entering/exiting the frozen state via key press. (Priority P1)

- [x] T007 [US1] Implement `requestStart` in `InteractionManager`: Set active state.
- [x] T008 [US1] Implement `requestEnd` in `InteractionManager`: Clear active state.
- [x] T009 [US1] Implement `tick` in `InteractionManager`: If active, manually tick Initiator and allow-listed systems (`TransformUpdateSys`, `CameraSetupSys`, `DisplaySys`) with `userInteractController`.
- [x] T009.5 [US1] Modify `DisplaySys` to pause Animation updates when `InteractionManager` is active, ensuring proper time rewind state continuity.
- [x] T010 [P] [US1] Create test system `Script/System/Tests/TestInteractionSys.lua` to trigger interaction on key press. Implement `tick_interaction` if needed.
- [x] T011 [US1] Verify physics pausing: Run `TestInteractionSys`, trigger mode, ensure entities stop (due to World loop skip).

## Phase 4: User Story 2 - Skill-Specific Behavior & Aiming
**Goal**: Allow specific logic (indicator) to run while the world is paused. (Priority P1)

- [x] T012 [US2] Update `InteractionManager` logic: `tick(dt, uic)` calls `initiator:tick_interaction(dt, uic)` (or regular `tick`).
- [x] T013 [P] [US2] Update test system to draw indicator.
- [x] T014 [US2] Implement Visual Overlay: Draw full-screen rect in `InteractionManager:draw`.
- [x] T015 [US2] Verify `InteractionManager` remains interactive while physics is paused.

## Phase 5: User Story 3 - Time Rewind Exclusion
**Goal**: Ensure the aiming phase is not recorded in time history. (Priority P2)

- [x] T016 [US3] Modify `Script/System/Gameplay/TimeRewindSys.lua` to check `InteractionManager:isActive()` and return early.
- [x] T017 [US3] Prevent `TimeRewindSys` from recording snapshots if interaction is active.
- [x] T018 [US3] Prevent `TimeRewindSys` from processing rewind input.
- [x] T019 [US3] Verify: Record actions, enter interaction, exit, rewind. Ensure interaction delay is skipped.

## Phase 6: Polish & Integration
**Goal**: Final cleanup and integration with actual gameplay systems.

- [x] T020 [Integration] Apply `tick_interaction` or similar logic if other systems need to run during mode (e.g., Camera).
- [x] T021 Run full regression test on `TestECSWorkflow.lua` to ensure no side effects on normal gameplay.

## Dependencies

1. **Setup -> Foundational**: `InteractionManager` and Events must exist before wiring them into `main.lua` or testing input block.
2. **Foundational -> US1**: World generic pause logic (T003/T004) must work before InteractionManager can use it in `requestStart`.
3. **US1 -> US2**: Must be able to enter mode before rendering indicators in that mode.
4. **US1 -> US3**: Time Rewind exclusion depends on `InteractionManager` state.

## Parallel Execution Examples

- **T003/T004 (World)** and **T005 (Input)** can be implemented in parallel.
- **T010 (Test System)** can be written while **T007-T009 (Manager Logic)** are being implemented.
- **T013 (Indicator Logic)** and **T014 (Visual Overlay)** are independent visual tasks.
