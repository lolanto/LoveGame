# PatrolCMP

This component enables AI patrol logic on an Entity. It holds the configuration and state for `PatrolSys`.

## associate systems
* [PatrolSys](../systems/patrol-system.md)

## member properties
### 1. patrolType (public)
Enum (`PatrolType`) indicating the behavior:
- `CIRCULAR_POINT`: Orbit a static point.
- `CIRCULAR_ENTITY`: Orbit another entity.
- `LINEAR_PATROL_POINTS`: Ping-pong between coordinates.
- `LINEAR_PATROL_ENTITIES`: Ping-pong between entities.

### 2. params (public)
Parameter object specific to the `patrolType` (e.g., center, radius, speed).

### 3. enabled (public)
Master switch for the behavior.

### 4. state (public)
Runtime state storage (e.g., "currently moving to point A").

## member functions
### 1. new(patrolType, params) (public)
Constructor. Validates parameters against the type.

### 2. setPatrol(type, params) (public)
Updates the patrol configuration dynamically.

### 3. setEnabled(bool) (public)
Enables/Disables the component.

## static properties
### 1. ComponentTypeName (public)
String identifier: "PatrolCMP".
### 2. ComponentTypeID (public)
Numeric ID registered with `BaseComponent`.

## static functions
(None)
