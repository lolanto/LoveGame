# PatrolSys

This system implements AI patrol behaviors such as circular movement around points/entities or linear movement between waypoints.

## associate components
* [PatrolCMP](../components/patrol-component.md)
* [MovementCMP](../components/movement-component.md)
* [TransformCMP](../components/transform-component.md)

## member properties
### 1. _requiredComponentInfos (protected)
Inherited from BaseSystem.
- `PatrolCMP`: Must have.
- `MovementCMP`: Must have.
- `TransformCMP`: Must have.

## member functions
### 1. new() (public)
Constructor. Registers requirements.

### 2. tick(deltaTime) (public)
Iterates over enabled `PatrolCMP` components and delegates to specific patrol logic functions based on `patrolType`.

### 3. executePatrol(patrolCmp, movementCmp, transformCmp, deltaTime) (private)
Dispatcher function that calls the specific patrol implementation (Circular Point, Circular Entity, Linear Points, etc.)

### 4. circularPointPatrol(...) (private)
Calculates velocity to orbit a specific coordinate. logic includes tangential velocity and radial correction.

### 5. circularEntityPatrol(...) (private)
Calculates velocity to orbit a target entity. Handles world-space calculations.

### 6. linearPatrolPoints(...) (private)
Manages state to move back and forth between two defined coordinates.

## static properties
### 1. SystemTypeName (public)
String identifier: "PatrolSys".

## static functions
(None)
