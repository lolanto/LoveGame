# LoveGame ECS Architecture

> This document describes the Entity-Component-System (ECS) architecture implemented in the LoveGame project. It serves as a technical reference for extending the engine and implementing gameplay features.

## 1. Architectural Overview

The project follows a **Modified ECS (Entity-Component-System)** pattern specifically adapted for Love2D. The core philosophy separates **Data (Components)** from **Logic (Systems)**, with **Entities** acting as the linking identity.

[architecture-systems.md](./architecture-systems.md) is index of all existing systems. Update it every time if a system being created or removed. The concrete description of each system is under folder `.specify/memory/systems`

[architecture-components.md](./architecture-components.md) is index of all existing components. Update it every time if a component being created or removed. The concrete description of each component is under folder `.specify/memory/components`

Key deviations/extensions from "Purist" ECS:
*   **Object-Oriented Components**: Components are Lua classes (tables) that can have inheritance and helper methods (e.g., getters/setters, `onBound`), but primarily store data.
*   **Entity Hierarchy**: Entities support a scene graph hierarchy (Parent-Child relationships) native to the Entity class.
*   **System Collection Phase**: Systems explicitly "collect" entities that match their requirements each frame, rather than maintaining long-lived cached lists automatically (though `collect` is optimized).

## 2. Core Concepts

### 2.1 Entity (`Script/Entity.lua`)
The `Entity` class is a container that holds:
*   **Identity**: Unique Name/ID.
*   **Components**: A map of `ComponentTypeID` -> `ComponentInstance`.
*   **Hierarchy**: References to `parentEntity` and a list of `childEntities`.
*   **State Flags**: `isVisible`, `isEnable`, `_needRewind` (Time Control).

**Key Responsibilities:**
*   Managing component lifecycle (`boundComponent`, `unboundComponent`).
*   Managing hierarchy (`boundChildEntity`).
*   Providing Component retrieval (Cast to ReadOnly or Mutable).

### 2.2 Component (`Script/BaseComponent.lua`)
The `BaseComponent` is the base class for all data containers.
*   **Type Registration**: Uses a static registry to map string names (`"TransformCMP"`) to numeric IDs for fast lookup.
*   **Data Only**: Should primarily contain state variables (fields).
*   **Interfaces**:
    *   `onBound(entity)` / `onUnbound()`: Lifecycle hooks.
    *   **Time Travel**: `getRewindState_const()`, `restoreRewindState(state)`, `lerpRewindState(a, b, t)` must be implemented for time-reversible components.
*   Component always should be bound to an entity before any of its interface being invoke!

### 2.3 System (`Script/BaseSystem.lua`)
The `BaseSystem` encapsulates logic. A system operates on a specific subset of entities.
*   **Requirements**: Defines a "Signature" of components an entity *must have* to be processed by this system.
    *   Defined via `addComponentRequirement(Type, RequirementDesc)`.
    *   Flags: `_mustHave` (filter), `_readOnly` (safety).
*   **Pipeline**:
    1.  `preCollect()`: Resets internal lists.
    2.  `collect(entity)`: Called for every active entity. Checks requirements. If matched, stores the required components in `_collectedComponents`.
    3.  `tick(deltaTime)`: Iterates over cached component tuples to execute logic.
    4.  `draw()`: (Optional) Rendering logic.
    5.  `processUserInput(controller)`: (Optional) Input handling.

## 3. The Game Loop

The main loop (orchestrated in `main.lua` and `LevelManager`) follows a specific execution order to ensure data consistency.

1.  **Event Dispatch**: `MessageCenter` processes queued events.
2.  **Pre-Update**: `UserInteractController` preparation.
3.  **Global Tick**: `LevelManager` ticks global entity logic (rarely used).
4.  **Scene Traversal**:
    *   Iterate all root entities.
    *   Flatten the hierarchy into a linear list for the frame (`thisFrameEntities`).
5.  **System Preparation (`preCollect`)**: All systems clear previous frame data.
6.  **Entity Collection**:
    *   For each entity in `thisFrameEntities`:
        *   Pass entity to **All Systems** via `collect(entity)`.
        *   System checks `_requiredComponentInfos`.
        *   If match: Stores references to components (auto-wrapping in `ReadOnly` if requested).
7.  **System Execution (`tick`)**:
    *   Systems iterate their own `_collectedComponents` lists.
    *   Special Order: `TimeDilation` and `TimeRewind` often run or influence `deltaTime` before others.
    *   Physics calculation -> Transform updates -> Logic -> Rendering.
8.  **Post-Update**: Cleanup.

## 4. Time Management Subsystem

The game features core mechanics around Time Manipulation (Rewind, Dilation). The ECS supports this natively:

*   **Time Rewind System (`TimeRewindSys`)**:
    *   Captures snapshots of components on entities marked with `_needRewind`.
    *   Components implement `getRewindState_const` to return serializable data.
    *   During rewind, the system overrides normal logic and calls `restoreRewindState`.
*   **Time Dilation (`TimeDilationSys`)**:
    *   Modifies global flow, but specific entities can be exceptions (`isTimeScaleException`).

## 5. Directory Structure & Extensions

*   `Script/Component/`: All Component classes.
    *   *Convention*: Name ends in `CMP.lua` (e.g., `TransformCMP.lua`).
    *   *Requirement*: Must register type in `new()` or file scope.
*   `Script/System/`: All System classes.
    *   *Convention*: Name ends in `Sys.lua` (e.g., `PhysicSys.lua`).
*   `Script/utils/`: Shared utilities (`ReadOnly.lua`, `MUtils.lua`).
