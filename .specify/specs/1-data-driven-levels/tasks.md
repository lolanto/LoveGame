# Tasks: Data-Driven Level System

**Feature Branch**: `1-data-driven-levels`
**Spec**: [spec.md](spec.md)
**Plan**: [plan.md](plan.md)

## Phase 1: Setup
Project initialization and directory structure.

- [x] T001 Create directory `Resources/Level` for data files
- [x] T002 Create directory `Script/Level` for logic scripts

## Phase 2: Foundational
Blocking prerequisites for checking out and loading data-driven levels.

- [x] T003 Implement `LevelManager:_loadDataFile(path)` with sandboxing (`setfenv`) in `Script/LevelManager.lua`
- [x] T004 Implement `LevelManager:_resolveComponent(className)` mapping logic in `Script/LevelManager.lua`
- [x] T005 Implement `LevelManager:_instantiateComponent(compData, systems)` factory with Dependency Injection (PhysicWorld) in `Script/LevelManager.lua`
- [x] T006 Implement `LevelManager:_applyComponentProperties(component, props)` property injector in `Script/LevelManager.lua` - **UPDATE**: Ensure this is called AFTER binding.
- [x] T007 Implement recursive `LevelManager:_buildEntity(entityData, parent, systems)` logic in `Script/LevelManager.lua` - **UPDATE**: Fix order: Instantiate -> Bind -> Properties -> Children.
- [x] T008 Update `LevelManager:requestLoadLevel` to support loading from `Resources/Level` path format in `Script/LevelManager.lua`

## Phase 3: User Story 1 - Load Level from Data
**Goal**: Decouple content from logic by loading Level 1 entities from a pure data file.

- [x] T009 [US1] Create `Resources/Level/Level1.lua` with static geometry (Ground, Walls) data
- [x] T010 [US1] Add Physics Debug and Ball entities to `Resources/Level/Level1.lua`
- [x] T011 [US1] Update `LevelManager:loadLevel` to execute the data-driven loading pipeline when a table is returned in `Script/LevelManager.lua`

## Phase 4: User Story 2 - Bind Logic Actions
**Goal**: Re-implement custom level logic (Triggers) using the separate Action Script approach.

- [x] T012 [US2] Implement `LevelManager:_bindComponentActions(component, bindings, actionScript)` in `Script/LevelManager.lua`
- [x] T013 [US2] Create `Script/Level/Level1.lua` containing `onLeftWallTrigger` logic
- [x] T014 [US2] Update `Resources/Level/Level1.lua` to bind `TriggerCMP` callback to `onLeftWallTrigger`
- [x] T015 [US2] Update `LevelManager` to load `Script/Level/LevelName.lua` (if exists) during level load in `Script/LevelManager.lua`

## Phase 5: User Story 3 - Level Switching
**Goal**: Complete the migration of Level 2 and verify end-to-end level transitions.

- [x] T016 [P] [US3] Create `Resources/Level/Level2.lua` with Ground and Wall entities
- [x] T017 [P] [US3] Create `Script/Level/Level2.lua` containing `onRightWallTrigger` logic
- [x] T018 [US3] Update `Script/Level/Level1.lua` to request load of `Resources.Level.Level2` (string path adjustment)
- [x] T019 [US3] Update `LevelManager` load request handling to map "Level2" to new data path if needed in `Script/LevelManager.lua`

## Phase 6: Polish & Cleanup
Cross-cutting concerns and legacy code removal.

- [x] T020 Remove legacy file `Levels/Level1.lua`
- [x] T021 Remove legacy file `Levels/Level2.lua`
- [x] T022 Update `Levels/BaseLevel.lua` or remove if no longer used (check dependency)
- [x] T023 Implement cleanup logic in `VirtualLevel:unload` to invoke `entity:onLeaveLevel` for all entities in `Script/LevelManager.lua`
- [x] T024 Implement Atomic Level Transition (Unload Previous -> Load Next in sequential order) in `LevelManager:loadLevel` to prevent frame overlap issues in `Script/LevelManager.lua`

## Dependencies & Parallelization

- **T003-T008** (LevelManager internals) must be done sequentially or by one dev.
- **T009 (US1 Data)** and **T016 (US3 Data)** can be done in parallel once schema is final.
- **T013 (US2 Logic)** and **T017 (US3 Logic)** can be done in parallel.

## Implementation Strategy
1.  **Skeleton**: Build the `LevelManager` loading parsing logic first (Phase 2).
2.  **Verify Data**: Migrate Level 1's static parts to verify rendering/physics (Phase 3).
3.  **Verify Logic**: Add the trigger logic to Level 1 to verify bindings (Phase 4).
4.  **Expansion**: Migrate Level 2 to prove the system handles switching (Phase 5).
