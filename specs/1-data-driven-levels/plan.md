# Implementation Plan: Data-Driven Level System

**Branch**: `1-data-driven-levels` | **Date**: 2026-02-08 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `spec.md`

## Summary

Refactor the current hardcoded level system into a data-driven architecture. Levels will be split into **Data** (Resources/Level/*.lua, returning pure tables) and **Logic** (Script/Level/*.lua, returning function tables). The `LevelManager` will be updated to load these files, instantiating entities and components data-driven, and binding trigger events to the logic scripts.

## Technical Context

**Language/Version**: Lua 5.1 (LuaJIT via Love2D)
**Primary Dependencies**: Love2D Engine, Internal ECS Framework
**Storage**: File System (Lua files as data)
**Testing**: Manual Playtesting (as per current project state)
**Project Type**: Single Game Application
**Constraints**:
*   Data files must be sandboxed (no access to globals/require).
*   Must maintain existing physics/gameplay behavior.
*   Pure ECS adherence (Entities are ID+Components).
*   **Initialization Safety**: Component Properties must only be applied AFTER binding the component to the entity to support `getParent()` calls during configuration.
*   **Resource Management**: Strict unloading lifecycle required. `VirtualLevel` must invoke `entity:onLeaveLevel()` on all managed entities to ensure physics bodies are destroyed.
*   **Atomic Transitions**: Level switching must occur sequentially (Unload -> Load) within the same frame to prevent Entity/Physics overlap (TC-006).

## Constitution Check

*   [x] **I. Pure ECS Architecture**: The plan reinforces this by defining levels as list of Entity+Components data.
*   [x] **II. Time-Aware System**: No change to system logic, so time manipulation remains compliant.
*   [x] **III. Physics-First**: Physics components are loaded from data, preserving the physics-driven nature.
*   [x] **IV. Modular & Compositional**: Level data explicitly composes entities from components.
*   [x] **V. Defensive Lua Programming**: Will use sandboxing (`setfenv`) for data loading to prevent global pollution.
*   [x] **Architecture Compliance**: Updated plan respects the strict "Bind-Before-Use" lifecycle rule.
*   [x] **Lifecycle Management**: Plan includes explicit teardown steps (`onLeaveLevel`) and atomic switching to resolve resource leaks and overlap bugs (FR-006, TC-006).

## Project Structure

### Documentation (this feature)

```text
.specify/specs/1-data-driven-levels/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
```

### Source Code

```text
LoveGame/
├── Resources/
│   └── Level/           # NEW: Level Data Files
│       ├── Level1.lua
│       └── Level2.lua
├── Script/
│   ├── Level/           # NEW: Level Logic Scripts
│   │   ├── Level1.lua
│   │   └── Level2.lua
│   ├── LevelManager.lua # MODIFIED: Data-driven loader
│   └── ...
└── ...
```

## Complexity Tracking

No violations anticipated.
