# PhysicVisualizeSys

A debug system responsible for rendering the shapes of physics bodies for visualization purposes.

## associate components
* [PhysicCMP](../components/physic-component.md)

## member properties
### 1. _requiredComponentInfos (protected)
Inherited from BaseSystem.
- `PhysicCMP`: Must have.

## member functions
### 1. new() (public)
Constructor. Registers requirement for `PhysicCMP`.

### 2. draw() (public)
Renders physics shapes.
- Saves current graphics state.
- Iterates over collected physics components.
- Sets color based on static (green transparent) vs dynamic (red transparent) state.
- Draws shapes (Circle or Rectangle) based on `PhysicCMP` shape data and body position.
- Restores graphics state.

## static properties
### 1. SystemTypeName (public)
String identifier: "PhysicVisualizeSys".

## static functions
(None)
