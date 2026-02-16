# Tasks: ECS World Refactor

**Spec**: [specs/003-ecs-world-refactor/spec.md](specs/003-ecs-world-refactor/spec.md)
**Plan**: [specs/003-ecs-world-refactor/plan.md](specs/003-ecs-world-refactor/plan.md)
**Status**: Complete

## Dependencies

- **Phase 1 (Core)**: Must be completed first. Provides the `World` and `ComponentsView` classes.
- **Phase 2 (System Integration)**: Depends on Phase 1. Updates `BaseSystem` and refactors existing systems.
- **Phase 3 (Lifecycle)**: Depends on Phase 1 & 2. Implements complex addition/removal logic and TimeRewind integration.
- **Phase 4 (Main Loop)**: Depends on all previous phases. Switches the engine driver.

---

## Phase 1: Core Infrastructure (Blocking)

**Goal**: Implement the foundational classes (`World`, `ComponentsView`) and update `Entity` structure.

- [x] T001 Create `Script/ComponentsView.lua` module structure with `ComponentsView.EMPTY` shared sentinel [Script/ComponentsView.lua](Script/ComponentsView.lua)
- [x] T002 Implement `ComponentsView` initialization and SoA arrays for optional/required components [Script/ComponentsView.lua](Script/ComponentsView.lua)
- [x] T003 Implement `ComponentsView:add(entity)` including `entity_to_index` map update [Script/ComponentsView.lua](Script/ComponentsView.lua)
- [x] T004 Implement `ComponentsView:remove(entity)` using `table.remove` (shift) and updating `entity_to_index` map for shifted elements [Script/ComponentsView.lua](Script/ComponentsView.lua)
- [x] T005 Implement `ComponentsView` View Key generation logic (Sort + ReadOnly flags) [Script/ComponentsView.lua](Script/ComponentsView.lua)
- [x] T006 Update `Script/Entity.lua` to include `_refCount`, `_world`, and `isArchDirty` properties. **Remedation (C2)**: Ensure component binding/unbinding calls `TimeRewind/World` dirty logic. [Script/Entity.lua](Script/Entity.lua)
- [x] T041 **Remediation (C1/C2)**: Implement `World:markEntityDirty(entity)` and ensure `Entity` notifies World on component change. [Script/World.lua](Script/World.lua)
- [x] T007 Implement `Entity:retain()` and `Entity:release()` methods for reference counting [Script/Entity.lua](Script/Entity.lua)
- [x] T008 Create `Script/World.lua` Singleton skeleton with strict `require` pattern (no global) [Script/World.lua](Script/World.lua)
- [x] T009 Implement `World:getComponentsView(requiredComponentInfos)` which parses `ComponentRequirementDesc` table to generate View Key and return cached View [Script/World.lua](Script/World.lua)

## Phase 2: System Integration

**Goal**: Update `BaseSystem` to use Views and refactor existing systems to register with World.

- [x] T010 Update `Script/BaseSystem.lua` to accept `World` in constructor, call `World:getComponentsView(self._requiredComponentInfos)`, and store the result in `self._componentsView` [Script/BaseSystem.lua](Script/BaseSystem.lua)
- [x] T011 Remove dynamic `BaseSystem:getComponentsView` wrapper (now a member variable) and ensure `BaseSystem:addComponentRequirement` is only used before initialization (or throws error if called after View creation) [Script/BaseSystem.lua](Script/BaseSystem.lua)
- [x] T012 Implement `World:registerSystem(system)` and `World:unregisterSystem(system)` [Script/World.lua](Script/World.lua)
- [x] T040 Implement `World:getSystem(systemName)` to allow retrieving registered systems [Script/World.lua](Script/World.lua)
- [x] T013 Refactor `Script/System/TransformUpdateSys.lua` to use `World` and `ComponentsView` [Script/System/TransformUpdateSys.lua](Script/System/TransformUpdateSys.lua)
- [x] T014 Refactor `Script/System/DisplaySys.lua` to use `World` and `ComponentsView` [Script/System/DisplaySys.lua](Script/System/DisplaySys.lua)
- [x] T015 Refactor `Script/System/EntityMovementSys.lua` to use `World` and `ComponentsView` [Script/System/EntityMovementSys.lua](Script/System/EntityMovementSys.lua)
- [x] T016 Refactor `Script/System/PhysicSys.lua` to use `World` and `ComponentsView` [Script/System/PhysicSys.lua](Script/System/PhysicSys.lua)
- [x] T017 [P] Refactor `Script/System/CameraSetupSys.lua` to use `World` and `ComponentsView` [Script/System/CameraSetupSys.lua](Script/System/CameraSetupSys.lua)
- [x] T018 [P] Refactor `Script/System/MainCharacterInteractSys.lua` to use `World` and `ComponentsView` [Script/System/MainCharacterInteractSys.lua](Script/System/MainCharacterInteractSys.lua)
- [x] T019 [P] Refactor `Script/System/Gameplay/BlackHoleSys.lua` to use `World` and `ComponentsView` [Script/System/Gameplay/BlackHoleSys.lua](Script/System/Gameplay/BlackHoleSys.lua)
- [x] T020 [P] Refactor `Script/System/Gameplay/PatrolSys.lua` to use `World` and `ComponentsView` [Script/System/Gameplay/PatrolSys.lua](Script/System/Gameplay/PatrolSys.lua)
- [x] T021 [P] Refactor `Script/System/Gameplay/TriggerSys.lua` to use `World` and `ComponentsView` [Script/System/Gameplay/TriggerSys.lua](Script/System/Gameplay/TriggerSys.lua)
- [x] T022 [P] Refactor `Script/System/Gameplay/TimeDilationSys.lua` to use `World` and `ComponentsView` [Script/System/Gameplay/TimeDilationSys.lua](Script/System/Gameplay/TimeDilationSys.lua)
- [x] T034 Implement `World:getMainCharacter()/setMainCharacter()` and `World:getMainCamera()/setMainCamera()` [Script/World.lua](Script/World.lua)
- [x] T035 Update `Script/main.lua` and Systems (`BlackHoleSys`, `LevelManager`) to use `World` special entity accessors instead of globals [Script/main.lua](Script/main.lua)

## Phase 3: Lifecycle & Time Rewind

**Goal**: Implement the complex addition/removal logic, Deferred Updates, Collision Events, and "Zombie" state for Time Rewind.

- [x] T023 Implement `World:addEntity(entity)` with recursion for children and adding to `pendingAdds` list [Script/World.lua](Script/World.lua)
- [x] T024 Implement `World:removeEntity(entity)` logic: recursive "Pending Destruction" marking and `componentsView` removal [Script/World.lua](Script/World.lua)
- [x] T042 **Remediation (C1)**: Update `World:clean()` to process `_dirtyEntities` list (re-evaluate Views for changed archetypes) before clear. [Script/World.lua](Script/World.lua)
- [x] T025 Implement `World:clean()` phase: Flush `pendingAdds` (add to Views), flush `pendingRemoves` (mark/remove from Views), and clear `dirtyEntities` [Script/World.lua](Script/World.lua)
- [x] T036 Implement `World:getAllManagedEntities()` (all valid) and `World:getActiveEntities()` (enabled only) [Script/World.lua](Script/World.lua)
- [x] T037 Implement `World:recordCollisionEvent(event)`, `World:getCollisionEvents()`, and `World:clearCollisionEvents()` [Script/World.lua](Script/World.lua)
- [x] T038 Update `Script/System/PhysicSys.lua` to push collision events to `World` instead of internal table [Script/System/PhysicSys.lua](Script/System/PhysicSys.lua)
- [x] T039 Update `Script/System/Gameplay/TriggerSys.lua` to pull collision events from `World` and remove direct dependency on `PhysicSys` [Script/System/Gameplay/TriggerSys.lua](Script/System/Gameplay/TriggerSys.lua)
- [x] T026 Implement **Zombie State** logic in `World`: If removed but `refCount > 0`, keep in implementation memory but remove from all Views [Script/World.lua](Script/World.lua)
- [x] T027 Implement `World` Garbage Collection tick: destroy entities in Pending Destruction list only if `refCount == 0` [Script/World.lua](Script/World.lua)
- [x] T028 Refactor `Script/System/Gameplay/TimeRewindSys.lua` to call `entity:retain()` on snapshot record and `entity:release()` on discard [Script/System/Gameplay/TimeRewindSys.lua](Script/System/Gameplay/TimeRewindSys.lua)

## Phase 4: Integration & Polish

**Goal**: Switch the main game loop to drive everything through `World` and verify correctness.

- [x] T029 Update `Script/LevelManager.lua` to use `World:addEntity` and `World:removeEntity` instead of direct table manipulation [Script/LevelManager.lua](Script/LevelManager.lua)
- [x] T030 Refactor main game loop to use `World:update()` and `World:draw()` [main.lua](main.lua)
- [x] T031 Validate `TimeRewindSys` prevents entity destruction during rewind (Verified via `Script/Tests/TestECSWorkflow.lua`)
- [x] T032 Validate Hierarchy destruction: Removing a parent correctly removes children from Views (Verified via `Script/Tests/TestECSWorkflow.lua`)
- [x] T033 Verify `ComponentsView` integrity: Entities added in frame N appear in Views in frame N+1 (Verified via `Script/Tests/TestECSWorkflow.lua`)

## Implementation Strategy

1.  **Bottom-Up**: Start with `ComponentsView` as it has no dependencies.
2.  **Singleton Core**: Build `World` incrementally. First just storage, then Views, then Lifecycle.
3.  **Refactor**: Port systems one by one. The game will be broken until `main.lua` is switched over in Phase 4.
