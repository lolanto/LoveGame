# DisplaySys

This system handles the rendering of entities that have visual components. It sorts entities by layer and issues draw calls.

## associate components
* [DrawableCMP](../components/drawable-component.md)
* [TransformCMP](../components/transform-component.md)

## member properties
### 1. _requiredComponentInfos (protected)
Inherited from BaseSystem.
- `DrawableCMP`: Must have.
- `TransformCMP`: Must have.

## member functions
### 1. new() (public)
Constructor. Registers requirements for `DrawableCMP` (must have) and `TransformCMP` (must have).

### 2. tick(deltaTime) (public)
Updates the animation state of `DrawableCMP` components (specifically `AnimationCMP` if present).

### 3. draw() (public)
Performs the actual rendering.
- Collects pairs of `DrawableCMP` and `TransformCMP`.
- Sorts them based on `DrawableCMP:getLayer()` (ascending order, though code says "larger value is more front", usually larger index draws later -> on top).
- Calls `drawableCmp:draw()` passing the entity's world transform.

## static properties
### 1. SystemTypeName (public)
String identifier: "DisplaySys".

## static functions
(None)
