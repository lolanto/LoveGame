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
 ECS/                 # [NEW] Folder for core ECS logic? Or keep in utils?
    ComponentsView.lua # [NEW] View logic
    Archetype.lua      # [NEW] Helper for signature optimization (optional)
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

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None      | N/A        | N/A                                 |

## Phases

### Phase 0: Outline & Research

1.  **Extract unknowns from Technical Context**:
    -   NEEDS CLARIFICATION: exact implementation of `ComponentsView` with Lua tables to avoid holes (nil).
    -   NEEDS CLARIFICATION: exact update timing for Views (deferred vs immediate).
    -   NEEDS CLARIFICATION: preserving update order in Views (Hierarchy).

2.  **Generate and dispatch research agents**:
    -   Task: "Research Lua best practices for dense arrays with optional holes (Sentinel values)."
    -   Task: "Evaluate performance trade-offs of Deferred vs Immediate View updates."
    -   Task: "Analyze impact on `TimeRewindSys` - how to hook into `World` ref counting."

3.  **Consolidate findings** in `research.md`.

### Phase 1: Design & Contracts

**Prerequisites**: `research.md` complete

1.  **Extract entities from feature spec**  `data-model.md`:
    -   `World`: Properties (entities, systems, views, queues, dirty lists).
    -   `ComponentsView`: Properties (signature, arrays, ref_count).
    -   `Entity` (Updates): `ref_count` + `isArchetypeDirty`.

2.  **Generate API contracts** from functional requirements:
    -   `World`: `addEntity`, `removeEntity`, `registerSystem`, `clean()`.
    -   `ComponentsView`: `iterate()`, `add(entity)`, `remove(entity)`.

3.  **Agent context update**:
    -   Update agent context with new core classes.

### Phase 2: Implementation Tasks

1.  **Core Implementation**:
    -   Create `ComponentsView.lua` (SoA + Table.remove).
    -   Create `World.lua` (Skeleton + Singleton logic + Dirty Queue).
    -   Update `Entity.lua` with reference counting & dirty flags.

2.  **System Integration**:
    -   Update `BaseSystem.lua` to accept `World` and request Views.
    -   Refactor all existing Systems (one by one/batch) to register with `World` and use Views.
        -   `TransformUpdateSys`, `DisplaySys`, etc.
    -   **Important**: Ensure Systems handle potentially deprecated entities delicately if interacting across Views (though Deferred updates mean Views are stable *per frame*).

3.  **Lifecycle & Time Rewind**:
    -   Implement `World:addEntity`/`removeEntity` recursive logic (Add to Pending lists).
    -   Implement `World:clean()`: Process Pending Adds/Removes AND Dirty Archetypes.
    -   Implement "Pending Destruction" queue and GC tick.
    -   Update `TimeRewindSys` to manipulate Entity ref counts.

4.  **Main Loop Refactor**:
    -   Update `main.lua` to delegate flow to `World`.
    -   Update `LevelManager` to use `World` for entity management.

5.  **Verification**:
    -   Verify standard gameplay (no regressions).
    -   Verify Time Rewind works (entities don't vanish prematurely).
    -   Verify View Consistency (newly added components appear next frame).
