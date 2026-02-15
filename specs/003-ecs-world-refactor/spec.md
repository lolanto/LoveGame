# ECS World Manager Refactor

## Status
- **State**: Draft
- **Phases**:
  - [ ] Analysis
  - [ ] Plan
  - [ ] Implementation

## Context
Refactor the current ECS system management to introduce a central `World` singleton. This class will manage Entities, Systems, and the Render Environment, acting as the core of the ECS architecture. It addresses lifecycle management (creation, destruction, time rewind compatibility), hierarchical entity handling, and optimized component querying via `ComponentsView`.

## Clarifications
### Session 2026-02-14
-   Q: Does the order of components in `ComponentsView` matter? -> A: Yes, order is significant (references Entity hierarchy/update order). Removal strategies must preserve order (no swap-and-pop).
### Session 2026-02-15
-   Q: Should `ComponentsView` updates (Add/Remove) be immediate or deferred? -> A: **Deferred**. Structural changes should apply at the start of the next Tick. Entities/Lists must carry "Dirty" flags so downstream Systems can detect invalidation if accessing mid-frame.
-   Q: How to handle optional component holes in ComponentsView? -> A: **Shared Global Sentinel**. Use a single immutable empty table (e.g. `ComponentsView.EMPTY`) to avoid allocation overhead.


## User Scenarios
1.  **Level Loading**: `LevelManager` instantiates a level. The level creates entities and calls `World:addEntity(entity)`. `World` recursively adds child entities and updates relevant `ComponentsView`s.
2.  **Level Unloading**: `LevelManager` calls `World:removeEntity(entity)` for all root entities in the level. `World` recursively marks them and children for removal. They enter a "pending destruction" state.
3.  **Gameplay Update**: Each frame, `World` updates systems. Systems iterate over components efficiently using `ComponentsView`s.
4.  **Time Rewind**: `TimeRewindSys` takes a snapshot. It increments the reference count of involved entities. Even if `removeEntity` was called, the entity remains in memory until the snapshot is discarded or rewind is complete and the ref count drops to zero.
5.  **System Initialization**: A new System (e.g., `TransformUpdateSys`) is created. It calls `addComponentRequirement('TransformCMP')`. `World` provides a `ComponentsView` populated with all `TransformCMP` components.

## Functional Requirements

### 1. World Global Singleton
-   **Central Management**: The `World` class must act as the singleton manager for:
    -   All active Entities.
    -   All active Systems.
    -   The Render Environment (`renderEnv`).
    -   Special global entities (e.g., `mainCharacterEntity`).

### 2. Entity Management
-   **Add Entity**:
    -   `World:addEntity(entity)`: Adds an entity to the game world.
    -   Must handle recursive addition of child entities.
    -   Must trigger updates to all relevant `ComponentsView`s (add entity's components to views if criteria matched).
-   **Remove Entity**:
    -   `World:removeEntity(entity)`: Marks an entity for removal.
    -   Must handle recursive removal of child entities.
    -   Entity enters a "Pending Destruction" state/queue.
    -   Must trigger updates to all relevant `ComponentsView`s (remove entity's components from views).
-   **State Changes**:
    -   Enabling/Disabling an entity (or component) should trigger similar updates to `ComponentsView` as add/remove.

### 3. Entity Lifecycle & Time Rewind Compatibility
-   **Pending Destruction Queue**: Entities marked for removal are not destroyed immediately. They are placed in a queue.
-   **Zombie State**: When `removeEntity` is called, if `refCount > 0` (e.g., held by Rewind), the entity enters "Zombie" state. It is removed from all Component Views (logic effectively stops) but `World` retains the memory reference until `refCount` drops to zero, primarily for serialization stability.
-   **Reference Counting**:
    -   All Entities must have a reference count.
    -   `TimeRewindSys` increments this count when an entity is included in a snapshot.
    -   `TimeRewindSys` decrements this count when a snapshot is consumed or discarded.
    -   Recursive reference counting: Incrementing/decrementing a parent's count recursively applies to children (Parent keeps Child alive).
    -   **Child-Parent Dependency**: Child entities do *not* increment their parent's reference count. It is assumed that if a child is retained (e.g., by TimeRewind), its parent is also retained. Debug builds should assert this integrity.
-   **Garbage Collection**:
    -   At the start of each `World` tick (or a visible cleanup phase), check the "Pending Destruction" queue.
    -   Only destroy entities (and their components) if their reference count is 0.

### 4. System Management
-   **Registration**: All Systems must register with the `World` (`World:registerSystem(system)`).
-   **Lifecycle**: Systems should be able to unregister (`World:unregisterSystem(system)`).
-   **Execution Order**: System execution order is determined by the explicit order of `system["Name"]:tick(dt)` calls in the code, providing manual control over dependency resolution.

### 5. ComponentsView System
-   **Definition**: A `ComponentsView` acts as a live query/cache for entities matching a specific **Archetype** (combination of required and optional components).
-   **Requirements Declaration**: Systems declare their dependencies via `_requiredComponentInfos` (table of `ComponentRequirementDesc`) in `BaseSystem`.
-   **View Acquisition**: Systems must obtain their `ComponentsView` exactly once during initialization in `System:new` by passing their requirement descriptor to `World:getComponentsView(requirements)`. The System then stores this View for its lifetime.
-   **Structure of Arrays (SoA)**:
    -   The View maintains parallel arrays for each requested component type.
    -   Index `i` in all arrays corresponds to the same Entity. **Order is significant** (e.g., for hierarchical updates).
    -   For optional components, if the Entity lacks that component, the array stores a **Shared Global Sentinel** (e.g., `ComponentsView.EMPTY`, wrapped as `ReadOnly` in debug) instead of `nil` or new tables. This prevents memory churn and ensures correct Lua array length semantics.
-   **View Creation & Sharing**:
    -   Views are keyed by their signature (Required + Optional sets).
    -   If a matching View exists, reuse it (increment ref count). Else create new.
-   **View Destruction**: Destroy when reference count hits zero.

### 6. ComponentsView Synchronization
-   **Initialization**: Populate immediately upon creation by scanning World entities.
-   **Deferred Updates**:
    -   Changes to Entity components (Add/Remove/Unbind/Disable) do *not* mutate Views immediately.
    -   Instead, they mark the Entity as "Dirty" or add to a "Pending Update" list.
    -   **Reconciliation**: At the start of the next `World` Tick (or specific synchronization point), process all pending updates to sync Views.
    -   **Flag Clearing**: `World` clears "Dirty" flags immediately after View synchronization (Clean Phase), before any System `tick` logic executes, ensuring a clean slate for the frame.
    -   *Crucial*: Systems accessing Views mid-frame after a change should either see the *old* valid state or be aware of the "Dirty" flag if they need absolute freshness (default to Old Valid State for stability).


## Success Criteria
-   **Centralized Control**: `main.lua` no longer manually manages list of entities/systems; it delegates to `World`.
-   **Safe Destruction**: Entities referenced by Time Rewind snapshots are guaranteed not to be nil/destroyed until safely released.
-   **Performance**: System iteration does not scan all entities; it iterates only over pre-filtered `ComponentsView`s.
-   **Correct Hierarchy**: Adding/Removing a parent entity correctly manages the lifecycle of the entire subtree.

## Assumptions
-   The current Entity/Component structure allows for adding a "reference count" property to the base Entity class.
-   `TimeRewindSys` logic is accessible and can be modified to call `World` or Entity ref-counting methods.
-   Systems currently iterate over a global list of entities; they will need to be refactored to iterate over `ComponentsView`.

## Technical Risks
-   **Circular References**: Ensure reference counting doesn't leak if entities reference each other (though the spec mainly focuses on Time Rewind references).
-   **Performance Overhead**: Check if the overhead of maintaining `ComponentsView`s (adding/removing from lists) upon every entity spawn/despawn is acceptable (likely yes, compared to iterating 1000s of entities every frame).
