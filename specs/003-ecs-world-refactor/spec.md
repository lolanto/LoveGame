# ECS World Manager Refactor# ECS World Manager Refactor





















































































-   **Performance Overhead**: Maintaining Views during rapid entity spawn/despawn events needs to be efficient.-   **Circular References**: Potential for memory leaks if entities reference each other in a way that prevents ref-counts from dropping to zero.## Technical Risks-   Systems currently iterating over global lists can be refactored to use the new View mechanism.-   Time manipulation logic can be integrated with the new World/Entity lifecycle.-   The current Entity/Component structure supports (or can be extended to support) reference counting.## Assumptions-   **Correct Hierarchy**: Adding/Removing a parent entity correctly manages the lifecycle of the entire subtree.-   **Performance**: System iteration uses pre-filtered views (O(N) where N is matching entities) effectively, rather than full world scans.-   **Safe Destruction**: Entities referenced by Time Rewind snapshots persist until safely released (reference count reaches zero).-   **Centralized Control**: Main application loop delegates entity/system management to `World`.## Success Criteria    -   When an entity is removed (or entity/component disabled): "Pending Remove" list processed before Tick. Update views.    -   When an entity is added (or entity/component enabled): "Pending Add" list processed before Tick. Update views.-   **Incremental Updates**:-   **Initialization**: Populate immediately upon creation.### 6. ComponentsView Synchronization-   **Data Structure**: The View should allow efficient iteration (e.g., providing a list of components).-   **View Destruction**: When a View's reference count drops to zero (no systems need it), it is destroyed.    -   If not, create a new View, populate it by scanning all current entities, and return it (ref count = 1).    -   If a View for a specific set of requirements already exists, return it and increment its View-specific reference count.-   **View Creation & Sharing**:-   **Requirements Declaration**: Systems declare their dependencies.-   **Definition**: A `ComponentsView` acts as a live query/cache for entities possessing specific components.### 5. ComponentsView System-   **Lifecycle**: Systems should be able to unregister.-   **Registration**: All Systems must register with the `World`.### 4. System Management    -   Only destroy entities (and their components) if their reference count is 0.    -   At the start of each World tick, check the "Pending Destruction" queue.-   **Garbage Collection**:    -   Recursive reference counting: Incrementing/decrementing a parent's count recursively applies to children.    -   Time manipulation systems decrement this count when a snapshot is consumed or discarded.    -   Time manipulation systems increment this count when an entity is included in a snapshot.    -   All Entities must have a reference count.-   **Reference Counting**:-   **Pending Destruction Queue**: Entities marked for removal are not destroyed immediately. They are placed in a queue.### 3. Entity Lifecycle & Time Rewind Compatibility    -   Enabling/Disabling an entity (or component) should trigger similar updates to component views as add/remove.-   **State Changes**:    -   Must trigger updates to all relevant component views.    -   Entity enters a "Pending Destruction" state/queue.    -   Must handle recursive removal of child entities.    -   Functionality to mark an entity for removal.-   **Remove Entity**:    -   Must trigger updates to all relevant component views.    -   Must handle recursive addition of child entities.    -   Functionality to add an entity to the game world.-   **Add Entity**:### 2. Entity Management    -   Special global entities.    -   The Render Environment.    -   All active Systems.    -   All active Entities.-   **Central Management**: The `World` class must act as the singleton manager for:### 1. World Global Singleton## Functional Requirements5.  **System Initialization**: A new System (e.g., `TransformUpdateSys`) is created. It declares requirements for `TransformCMP`. `World` provides a view populated with all entities having `TransformCMP`.4.  **Time Rewind**: `TimeRewindSys` takes a snapshot. It increments the reference count of involved entities. Even if removal was requested, the entity remains in memory until the snapshot is discarded or rewind is complete and the ref count drops to zero.3.  **Gameplay Update**: Each frame, `World` updates systems. Systems iterate over entities efficiently using cached views.2.  **Level Unloading**: `LevelManager` requests removal of entities for all root entities in the level. `World` recursively marks them and children for removal. They enter a "pending destruction" state.1.  **Level Loading**: `LevelManager` instantiates a level. The level creates entities and calls `World` to add specific entities. `World` recursively adds child entities and updates relevant filters.## User ScenariosRefactor the current ECS system management to introduce a central `World` singleton. This class will manage Entities, Systems, and the Render Environment, acting as the core of the ECS architecture. It addresses lifecycle management (creation, destruction, time rewind compatibility), hierarchical entity handling, and optimized component querying via `ComponentsView`.## Context  - [ ] Implementation  - [ ] Plan  - [ ] Analysis- **Phases**:- **State**: Draft## Status
## Status
- **State**: Draft
- **Phases**:
  - [ ] Analysis
  - [ ] Plan
  - [ ] Implementation

## Context
Refactor the current ECS system management to introduce a central `World` singleton. This class will manage Entities, Systems, and the Render Environment, acting as the core of the ECS architecture. It addresses lifecycle management (creation, destruction, time rewind compatibility), hierarchical entity handling, and optimized component querying via `ComponentsView`.

## User Scenarios
1.  **Level Loading**: `LevelManager` instantiates a level. The level creates entities and calls `World:addEntity(entity)`. `World` recursively adds child entities and updates relevant `ComponentsView`s.
2.  **Level Unloading**: `LevelManager` calls `World:removeEntity(entity)` for all root entities in the level. `World` recursively marks them and children for removal. They enter a "pending destruction" state.
3.  **Gameplay Update**: Each frame, `World` updates systems. Systems iterate over entities efficiently using `ComponentsView`s.
4.  **Time Rewind**: `TimeRewindSys` takes a snapshot. It increments the reference count of involved entities. Even if `removeEntity` was called, the entity remains in memory until the snapshot is discarded or rewind is complete and the ref count drops to zero.
5.  **System Initialization**: A new System (e.g., `TransformUpdateSys`) is created. It calls `addComponentRequirement('TransformCMP')`. `World` provides a `ComponentsView` populated with all entities having `TransformCMP`.

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
-   **Reference Counting**:
    -   All Entities must have a reference count.
    -   `TimeRewindSys` increments this count when an entity is included in a snapshot.
    -   `TimeRewindSys` decrements this count when a snapshot is consumed or discarded.
    -   Recursive reference counting: Incrementing/decrementing a parent's count recursively applies to children.
-   **Garbage Collection**:
    -   At the start of each `World` tick (or a visible cleanup phase), check the "Pending Destruction" queue.
    -   Only destroy entities (and their components) if their reference count is 0.

### 4. System Management
-   **Registration**: All Systems must register with the `World` (`World:registerSystem(system)`).
-   **Lifecycle**: Systems should be able to unregister (`World:unregisterSystem(system)`).

### 5. ComponentsView System
-   **Definition**: A `ComponentsView` acts as a live query/cache for entities possessing specific components.
    -   e.g., A view for `['TransformCMP']` contains a list of all entities with a `TransformCMP`.
-   **Requirements Declaration**: Systems declare their dependencies via `addComponentRequirement`.
-   **View Creation & Sharing**:
    -   If a View for a specific set of requirements already exists, return it and increment its View-specific reference count.
    -   If not, create a new View, populate it by scanning all current entities, and return it (rc=1).
-   **View Destruction**: When a View's reference count drops to zero (no systems need it), it is destroyed.
-   **Data Structure**: The View should allow efficient iteration. The user specification mentions a dictionary with Component class names as keys and lists of components as values.
    -   *Clarification*: The requirement mentions "dict ... array ... every entity ... its component". This implies the view might just provide a flat list of *Components* or *Entities* depending on usage. We will implement what provides efficient iteration for the System.

### 6. ComponentsView Synchronization
-   **Initialization**: Populate immediately upon creation.
-   **Incremental Updates**:
    -   When `addEntity` is called (or entity/component enabled): "Pending Add" list processed before Tick. Update views.
    -   When `removeEntity` is called (or entity/component disabled): "Pending Remove" list processed before Tick. Update views.

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
