# MovementCMP

This component stores velocity data for an entity, allowing `EntityMovementSys` to update its position.

## associate systems
* [EntityMovementSys](../systems/entity-movement-system.md)
* [MainCharacterInteractSys](../systems/main-character-interact-system.md) (sets velocity)
* [PatrolSys](../systems/patrol-system.md) (sets velocity)

## member properties
### 1. _velocityX (protected)
Velocity along the X-axis in meters per second.
### 2. _velocityY (protected)
Velocity along the Y-axis in meters per second.
### 3. _affectMode (protected)
Determines how movement is applied:
- `"local"` (Default): Updates the Entity's local transform (`TransformCMP`).
- `"world"`: Updates the Entity's world transform (useful for physics-driven or absolute movement).

## member functions
### 1. new() (public)
Constructor. Initializes velocity to (0,0) and mode to "local".

### 2. setVelocity(vx, vy) (public)
Sets the velocity vector.

### 3. setAffectMode(mode) (public)
Sets the movement application mode ("local" or "world").

### 4. getAffectMode_const() (public)
Returns the current affect mode.

### 5. getVelocity_const() (public)
Returns `(vx, vy)`.

## static properties
### 1. ComponentTypeName (public)
String identifier: "MovementCMP".
### 2. ComponentTypeID (public)
Numeric ID registered with `BaseComponent`.

## static functions
(None)
