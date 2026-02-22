# LoveGame ECS Architecture

> This document describes the Entity-Component-System (ECS) architecture implemented in the LoveGame project. It serves as a technical reference for extending the engine and implementing gameplay features.

## 1. Architectural Overview

The project follows a **Modified ECS (Entity-Component-System)** pattern specifically adapted for Love2D. The core philosophy separates **Data (Components)** from **Logic (Systems)**, managed by a central **World** singleton.

[architecture-systems.md](./architecture-systems.md) is index of all existing systems. Update it every time if a system being created or removed. The concrete description of each system is under folder `.specify/memory/systems`

[architecture-components.md](./architecture-components.md) is index of all existing components. Update it every time if a component being created or removed. The concrete description of each component is under folder `.specify/memory/components`

Key deviations/extensions from "Purist" ECS:
*   **Object-Oriented Components**: Components are Lua classes (tables) that can have inheritance and helper methods (e.g., getters/setters, `onBound`), but primarily store data.
*   **Entity Hierarchy**: Entities support a scene graph hierarchy (Parent-Child relationships) native to the Entity class.
*   **Archetype Views**: Systems query entities using **ComponentsView**, which maintains cached lists of entities matching specific component signatures (Archetypes), optimized for O(1) or O(N_matching) iteration.

## 2. Core Concepts

### 2.0 World (`Script/World.lua`)
The `World` is the central singleton that manages the lifecycle of all:
*   **Entities**: Creation (`addEntity`), Destruction (`removeEntity`), and Storage.
*   **Systems**: Registration and execution order.
*   **Views**: Caching and updating `ComponentsView`s.
*   **Global State**: Active Camera, Main Character, Collision Events.

**Key Responsibilities:**
*   **Deferred Updates**: Entity structure changes (add/remove components/entities) are queued and applied at the start of the next frame to ensure stability during iteration.
*   **Garbage Collection**: Manages "Zombie" entities (removed but referenced by TimeRewind) via reference counting.

### 2.1 Entity (`Script/Entity.lua`)
The `Entity` class is a container that holds:
*   **Identity**: Unique Name/ID.
*   **Components**: A map of `ComponentTypeID` -> `ComponentInstance`.
*   **Hierarchy**: References to `parentEntity` and a list of `childEntities`.
*   **State Flags**: `isVisible`, `isEnable`, `_needRewind` (Time Control).
*   **World State**: Reference count (`retain`/`release`) and "Dirty" flags for archetype updates.

**Key Responsibilities:**
*   Managing component lifecycle (`boundComponent`, `unboundComponent`).
*   Managing hierarchy (`boundChildEntity`).
*   Managing active state (`setEnable`) and visibility (`setVisible`).
*   Notifying `World` of component changes (`setIsArchDirty`).

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
*   **Views**:
    *   Systems obtain a `ComponentsView` from `World` during initialization based on requirements.
    *   Iterate over the view in `tick(deltaTime)`: `for i = 1, view:getCount() do ... end`.

### 2.4 ComponentsView (`Script/ComponentsView.lua`)
A `ComponentsView` provides an optimized, cached view of entities matching a specific requirement signature.
*   **Structure of Arrays (SoA)**: Components are stored in parallel arrays for cache efficiency.
*   **Shared Sentinel**: Optional missing components trigger a fallback to a shared immutable empty table (`ComponentsView.EMPTY`).
*   **Deferred Sync**: Views are updated only during the `World:clean()` phase, ensuring iteration consistency within a frame.

## 3. The Game Loop

The main loop (orchestrated in `main.lua` and `Script/World.lua`) follows a specific execution order:

1.  **Event Dispatch**: `MessageCenter` processes queued events.
2.  **Pre-Update**: `UserInteractController` preparation.
3.  **World Clean (Reconciliation)**:
    *   Process `_pendingAdds` (Add to World and Views).
    *   Process `_dirtyEntities` (Update View membership for changed components/enable state).
    *   Process `_pendingRemoves` (Remove from World/Views -> Zombie State).
    *   Garbage Collection (Destroy Zombies with refCount == 0).
    *   Clear Collision Events.
4.  **Interaction Mode Check**:
    *   If `InteractionManager` is active, the **Standard Update (Step 5)** is skipped.
    *   Instead, `InteractionManager` manually ticks:
        *   `CameraSetupSys` (Visuals)
        *   `DisplaySys` (Rendering)
        *   The **Initiator System** (e.g., `BlackHoleSys`) creating the interaction.
5.  **Standard System Update** (If not in Interaction Mode):
    *   `World` iterates registered systems and calls `tick(dt)`.
    *   Systems iterate their `ComponentsView` to execute logic.
    *   **Logic Flow**: Physics -> Logic -> Transform Updates -> Rendering.
5.  **Drawing**: `World` iterates systems and calls `draw()`. `InteractionManager` has its own `draw()`.

## 4. Interaction Mode & Special States

The ECS loop is interruptible by the **InteractionManager** (`Script/InteractionManager.lua`) to support complex gameplay mechanics (e.g., Skill targeting, Quick Time Events).

*   **Activation**: A system calls `InteractionManager:requestStart(self, timeout, context)`.
*   **State**: The Global World update is paused. Physics and irrelevant logic stop ticking.
*   **Delegation**: The initiating system takes control. It receives `tick_interaction(dt, input)` callbacks from the manager.
*   **Visuals**: Camera and Rendering systems continue to update to prevent the screen from freezing, but the game state remains static unless modified by the initiator.

## 5. Time Management Subsystem

The game features core mechanics around Time Manipulation (Rewind, Dilation). The ECS supports this natively:

*   **Time Rewind System (`TimeRewindSys`)**:
    *   Captures snapshots of components on entities marked with `_needRewind`.
    *   Components implement `getRewindState_const` to return serializable data.
    *   During rewind, the system overrides normal logic and calls `restoreRewindState`.
*   **Time Dilation (`TimeDilationSys`)**:
    *   Modifies global flow, but specific entities can be exceptions (`isTimeScaleException`).

## 6. Directory Structure & Extensions

*   `Script/Component/`: All Component classes.
    *   *Convention*: Name ends in `CMP.lua` (e.g., `TransformCMP.lua`).
    *   *Requirement*: Must register type in `new()` or file scope.
*   `Script/System/`: All System classes.
    *   *Convention*: Name ends in `Sys.lua` (e.g., `PhysicSys.lua`).
*   `Script/utils/`: Shared utilities (`ReadOnly.lua`, `MUtils.lua`).

## 7. Level & Scene Management

The `LevelManager` (`Script/LevelManager.lua`) orchestrates the game world state, acting as the bridge between Data-Driven Level definitions and the ECS runtime.

### 7.1 Level Lifecycle

The LevelManager employs an **Atomic Transition** strategy for level switching to ensure state consistency.

*   **Loading Flow via `loadLevel`**:
    1.  **Implicit Unload**: Immediately unloads the `_currentLevel` (if any) to prevent entities from overlapping or leaking.
    2.  **Cleanup**: Processes any pending unloads in `_unloadLevelsList` to ensure a clean slate.
    3.  **Instantiation**: Creates a new instance of the target Level class (or `VirtualLevel`).
    4.  **Registration**: Calls `level:load(systems)` to parse data files and build entities. Then calls `World:addEntity()` for root entities.
    5.  **Event**: Broadcasts `Event_LevelLoaded`.

*   **Unloading Flow**:
    *   Iterates through entities tracked by the Level instance.
    *   Invokes `entity:onLeaveLevel()`.
    *   Calls `World:removeEntity()` for each root entity to queue for destruction.
    *   Broadcasts `Event_LevelUnloaded`.

### 7.2 Data-Driven Levels ("Virtual Levels")

While Levels can be Lua classes, the engine supports **Data-Driven Levels** loaded directly from `Resources/Level/*.lua` files.

*   **Behavior**: `LevelManager:requestLoadLevel('LevelName')` detects if a corresponding Lua class exists. If not, it looks for `Resources/Level/LevelName.lua` and wraps it in a **VirtualLevel** closure.
*   **Structure**: Data files return a table describing the scene graph:
    ```lua
    return {
        name = "Level1",
        entities = {
            {
                name = "player",
                enable = true, -- Default: true
                visible = true, -- Default: true
                components = { ... },
                children = { ... }
            }
        }
    }
    ```
*   **Sandbox**: Data files are loaded in a restricted environment for safety.

### 7.3 Entity Instantiation Logic

The `_buildEntity` pipeline is responsible for constructing entities from data:

1.  **Factory**: Creates `Entity` instance.
2.  **Default State**:
    *   `isEnable`: Defaults to **true** (Active).
    *   `isVisible`: Defaults to **true** (Visible).
    *   *Note*: Explicit values in data override defaults.
3.  **Component Injection**:
    *   Resolves component classes by name (e.g., `PhysicCMP`).
    *   Performs **Dependency Injection** (e.g., injecting `PhysicSys:getWorld()` into physics components).
    *   Applies property overrides via Setters (e.g., `worldPosition` -> `setWorldPosition`).
4.  **Hierarchy**: Recursively builds and binds children.
5.  **Scripting**: Links "Action Scripts" (from `Script/Level/LevelName.lua`) to component callbacks if defined.
