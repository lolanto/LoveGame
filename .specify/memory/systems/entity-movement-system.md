# EntityMovementSys

This system controls the movement of entities by updating their `TransformCMP` based on velocity data in `MovementCMP`.

## associate components
* [MovementCMP](../components/movement-component.md)
* [TransformCMP](../components/transform-component.md)

## member properties
### 1. _requiredComponentInfos (protected)
Inherited from BaseSystem.
- `MovementCMP`: Must have.
- `TransformCMP`: Must have.

## member functions
### 1. new() (public)
Constructor. Registers requirements for `MovementCMP` (must have) and `TransformCMP` (must have).

### 2. tick(deltaTime) (public)
Updates positions for all collected entities.
- Calculates delta time (respecting Time Dilation via `TimeManager`).
- Retrieves velocity from `MovementCMP`.
- Calculates displacement (`dx`, `dy`).
- Applies displacement to `TransformCMP`.
  - If `MovementCMP` affect mode is "local" (default), uses `transformCmp:translate`.
  - If "world", uses `transformCmp:translateWorldPosition`.

## static properties
### 1. SystemTypeName (public)
String identifier: "EntityMovementSys".

## static functions
(None)
