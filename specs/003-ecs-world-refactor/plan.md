# Implementation Plan: ECS World Refactor

**Branch**: `003-ecs-world-refactor` | **Date**: 2026-02-15 | **Spec**: [specs/003-ecs-world-refactor/spec.md](specs/003-ecs-world-refactor/spec.md)
**Input**: Feature specification from `specs/003-ecs-world-refactor/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Refactor the current ECS architecture to introduce a central `World` singleton manager. This `World` class will handle all Entity and System lifecycles, ensuring proper recursive addition/removal of entities, valid hierarchy management, and compatibility with the Time Rewind system through reference counting. It will also introduce an optimized `ComponentsView` system to allow Systems to efficiently query entities based on component archetypes (Required + Optional components), replacing full-world scans.

## Technical Context

**Language/Version**: Lua 5.1/LuaJIT (Love2D environment)
**Primary Dependencies**: None (Standard Lua + Project Utils)
**Storage**: In-memory (Lua Tables)
**Testing**: Manual conversion of existing logic + Integration Tests
**Target Platform**: Windows/Mac/Linux (Love2D supported)
**Project Type**: Game Engine Core
**Performance Goals**: 
-   O(1) or O(N_view) iteration for Systems (vs current O(N_all)).
-   Minimal garbage generation during frame updates.
-   Efficient entity addition/removal (avoiding massive table reallocations).
**Constraints**: 
-   Must integrate with existing `TimeRewindSys` and `LevelManager`.
-   Must support hierarchical entity updates.
**Scale/Scope**: Core architecture change affecting all Systems and Entities.

## Constitution Check

*GATE: Passed.*

-   **Pure ECS Architecture**: The refactor enforces strict separation by centralizing logic in Systems and data in Components, managed by `World`. `ComponentsView` ensures Systems only see what they need.
-   **Time-Aware System Design**: The `World` design explicitly includes reference counting for `TimeRewindSys` compatibility, ensuring entities persist during rewind even if logically removed.
-   **Modular & Compositional Design**: `ComponentsView` supports archetype-based querying, reinforcing compositional design.
-   **No Global Variables**: `World` will be a Singleton module, required explicitly, rather than a global variable (following `MUtils` pattern).

## Project Structure

### Documentation (this feature)

```text
specs/003-ecs-world-refactor/
 plan.md              # This file (/speckit.plan command output)
 research.md          # Phase 0 output (/speckit.plan command)
 data-model.md        # Phase 1 output (/speckit.plan command)
 quickstart.md        # Phase 1 output (/speckit.plan command)
 contracts/           # Phase 1 output (/speckit.plan command)
 tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
Script/
 World.lua            # [NEW] Main World Singleton
 ComponentsView.lua   # [NEW] View logic
 Entity.lua           # [UPDATE] Add ref counting & world context
 BaseSystem.lua       # [UPDATE] Add registration logic & view retrieval
 main.lua             # [UPDATE] Use World for update/draw loop
 System/
     ... (All Systems updated to use World & Views)
```

**Structure Decision**: 
-   New `World.lua` in `Script/`. 
-   `ComponentsView` implementation detailed in `Script/ComponentsView.lua` (or similar).
-   Modifications to `Entity.lua` and `BaseSystem.lua`.
-   (*Change*): Removed `Archetype.lua` - logic consolidated into `ComponentsView` utils.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None      | N/A        | N/A                                 |

## Phases

### Phase 0: Outline & Research

1.  **Extract unknowns from Technical Context**:
    -   (Resolved) Implementation of `ComponentsView`: Shared Global Sentinel.
    -   (Resolved) Update Timing: Deferred Updates.
    -   (Resolved) Hierarchy: Preserve Order with `table.remove`.

2.  **Generate and dispatch research agents**:
    -   (Done) Research best practices for sparse/optional components.
    -   (Done) Evaluate View update strategies.
    -   (Done) Research canonical View Key generation (Sorted + ReadOnly flags).
    -   (Done) Define Entity-to-Index strategy for ComponentsView (Reverse Map + Shift).

3.  **Consolidate findings**:
    -   See `specs/003-ecs-world-refactor/research.md`.

### Phase 1: Design & Contracts

**Prerequisites**: `research.md` complete

1.  **Extract entities from feature spec** -> `data-model.md`:
    -   Defined `World`, `ComponentsView`, and `Entity` extensions.
    -   See `specs/003-ecs-world-refactor/data-model.md`.

2.  **Generate API contracts**:
    -   Contracts created in `specs/003-ecs-world-refactor/contracts/`.
    -   `World.lua` and `ComponentsView.lua` interfaces defined.

3.  **Agent context update**:
    -   (Pending) Update agent context with new core classes.

### Phase 2: Implementation Tasks

1.  **Core Implementation**:
    -   Create `ComponentsView.lua`:
        -   Implement SoA structure with Shared Global Sentinel (`ComponentsView.EMPTY`).
        -   Implement `entity_to_index` map (Reverse Index) for O(1) entity lookup during removal.
        -   Implement removal via `table.remove` (shift) to preserve order, iterating to update `entity_to_index` for shifted elements.
    -   Create `World.lua` (Skeleton + Singleton logic + Dirty Queue).
    -   Update `Entity.lua` with reference counting & dirty flags.
    -   Implement `World:getComponentsView(componentRequirements)` which parses `_requiredComponentInfos`, generates a canonical View Key, and returns a cached/new View.

2.  **System Integration**:
    -   Update `BaseSystem.lua`:
        -   Accept `World` in constructor.
        -   Call `World:getComponentsView(self._requiredComponentInfos)` in `new` (or `init`) and store `self._componentsView`.
    -   Refactor all existing Systems (one by one/batch) to register with `World` and use Views.
        -   `TransformUpdateSys`, `DisplaySys`, etc.
    -   **Important**: Ensure Systems handle potentially deprecated entities delicately if interacting across Views (though Deferred updates mean Views are stable *per frame*).

3.  **Lifecycle & Time Rewind**:
    -   Implement `World:addEntity`/`removeEntity` recursive logic (Add to Pending lists).
    -   Implement `World:clean()`: Process Pending Adds/Removes AND Dirty Archetypes.
    -   Implement `World:getActiveEntityList()`: Return a cached list of non-destroyed entities for the current frame (optimized for Systems like TimeRewind that iterate all). Logic involves iterating all entities and checking `not entity:isDestroyed()`, returning a flat integer-indexed table.
    -   Implement "Pending Destruction" queue and GC tick.
    -   Implement `World:recordCollisionEvent(event)`, `World:getCollisionEvents()`, and `World:clearCollisionEvents()` for transient frame-based event handling.
    -   Update `TimeRewindSys` to manipulate Entity ref counts.

4.  **Main Loop Refactor**:
    -   Update `main.lua` to delegate flow to `World`.
    -   Update `LevelManager` to use `World` for entity management.
    -   Implement `World` accessors for `mainCharacter` and `mainCamera`.
    -   Remove global `mainCharacterEntity` and `mainCameraEntity` variables, using `World:getMainCharacter()` instead.

5.  **Verification**:
    -   Verify standard gameplay (no regressions).
    -   Verify Time Rewind works (entities don't vanish prematurely).
    -   Verify View Consistency (newly added components appear next frame).
