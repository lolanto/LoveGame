# Feature Specification: Data-Driven Level System

**Feature Branch**: `1-data-driven-levels`
**Created**: 2026-02-08
**Status**: Draft
**Input**: User description: "Separate level definition into Data (Resources/Level) and Logic (Script/Level). Update LevelManager to load from these files."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Load Level from Data (Priority: P1)

As a developer, I want to define level entities and components in a data-only file, so that content creation is decoupled from game logic.

**Why this priority**: Core of the refactoring request.

**Independent Test**: Create a simple test level data file and verify `LevelManager` can instantiate the entities correctly.

**Acceptance Scenarios**:

1. **Given** a data file `Resources/Level/TestLevel.lua` describing an entity with a `TransformCMP`, **When** `LevelManager` loads this level, **Then** an entity with `TransformCMP` exists in the game world with correct values.
2. **Given** the data file specifies a `DebugColorBlockCMP`, **When** loaded, **Then** the entity is rendered correctly (visual verification).

### User Story 2 - Bind Logic Actions (Priority: P1)

As a level designer, I want to bind specific trigger events to functions defined in a separate script file, so that I can implement custom level logic without modifying the engine.

**Why this priority**: Essential to support current functionality (triggers, level switching).

**Independent Test**: Create a trigger entity in data that links to a function in the action file.

**Acceptance Scenarios**:

1. **Given** an entity with `TriggerCMP` in data file referencing callback `onTriggerEnter`, **And** an action file `Script/Level/TestLevelActions.lua` defining `onTriggerEnter`, **When** the player enters the trigger, **Then** the `onTriggerEnter` function is executed.

### User Story 3 - Level Switching (Priority: P2)

As a player, I want to transition between levels seamlessly using the new system.

**Why this priority**: Verifies the end-to-end integration.

**Independent Test**: Use the refactored Level1 and Level2.

**Acceptance Scenarios**:

1. **Given** the player is in Level 1 (refactored), **When** they hit the wall trigger, **Then** Level 2 (refactored) is loaded.
2. **Given** the player is in Level 2, **When** they hit the return trigger, **Then** Level 1 is loaded.

### Edge Cases

- **Missing Action File**: If a level has data but no action file, it should load fine (just no custom logic bindings).
- **Missing Component Reference**: If data names a component class that cannot be found, the loader should log an error and skip that component (or entity), preventing a crash.
- **Invalid Properties**: If properties provided in data don't match what the Component constructor expects.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST support loading level definitions from external data sources.
- **FR-002**: System MUST allow defining entity properties (position, type, configuration) via purely descriptive data.
- **FR-003**: System MUST allow linking entities in data to specific gameplay behaviors defined in logic scripts.
- **FR-004**: Users MUST be able to transition between levels based on trigger events defined in the data.
- **FR-005**: All existing content from "Level 1" and "Level 2" MUST be preserved and functional in the new system.
- **FR-006**: System MUST properly unload all resources (Entities, Physics Bodies) when unloading a level to prevent memory leaks or physics artifacts.

### Technical Constraints

- **TC-001**: Level data MUST be stored in Lua tables in `Resources/Level` directory.
- **TC-002**: Level logic MUST be stored in Lua scripts in `Script/Level` directory.
- **TC-003**: The data format MUST NOT contain explicit code execution (e.g., `require`).
- **TC-004**: Logic bindings MUST use string-based references to function names.
- **TC-005**: **Strict Initialization Order**: Components MUST be bound to their Entity (`entity:boundComponent`) *before* any properties are applied or methods are called on them (except the constructor). This ensures dependency resolution (like `getParentTransform`) works correctly.
- **TC-006**: **Atomic Unloading**: The system MUST ensures that the previous level's entities are fully unloaded (or at least their physics bodies are destroyed/disabled) **BEFORE** the new level's entities are instantiated. This is to prevent physics interference (overlapping bodies) or logic conflicts (immediate re-triggering) during the transition frame.

### Key Entities

- **Level Definition**: Represents the static layout of a game level.
- **Behavior Script**: Represents the dynamic logic associated with a level.

## Success Criteria

- **SC-001**: Users can load Level 1 and Level 2 with identical visual and physical behavior to the previous version.
- **SC-002**: Level transitions (Level 1 -> Level 2 -> Level 1) occur correctly upon triggering the defined zones.
- **SC-003**: New levels can be created by adding files to the data directory without modifying core engine code.
