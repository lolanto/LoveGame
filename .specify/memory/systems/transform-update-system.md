# TransformUpdateSys

This system maintains the scene graph hierarchy by calculating world transformations from local transformations.

## associate components
* [TransformCMP](../components/transform-component.md)

## member properties
### 1. _requiredComponentInfos (protected)
Inherited from BaseSystem.
- `TransformCMP`: Must have.

## member functions
### 1. new() (public)
Constructor. Registers requirement for `TransformCMP`.

### 2. tick(deltaTime) (public)
Updates transform matrices.
- Iterates over all `TransformCMP` components.
- Calls `transform:updateTransforms()`.
- *Note*: The `TransformCMP` logic handles recursion to ensure parent transforms are updated before children.

## static properties
### 1. SystemTypeName (public)
String identifier: "TransformUpdateSys".

## static functions
(None)
