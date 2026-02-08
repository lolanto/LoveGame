# CameraSetupSys

This system is responsible for setting up the camera configuration for the rendering environment based on the camera entity's state.

## associate components
* [CameraCMP](../components/camera-component.md)
* [TransformCMP](../components/transform-component.md)

## member properties
### 1. _requiredComponentInfos (protected)
Inherited from BaseSystem. Stores the requirement description for components.
- `CameraCMP`: Must have.
- `TransformCMP`: Must have.

## member functions
### 1. new(o) (public)
Constructor. Registers component requirements: `CameraCMP` (must have, readonly) and `TransformCMP` (must have, readonly).

### 2. collect(entity) (public)
Overrides `BaseSystem:collect`. Collects `CameraCMP` and `TransformCMP` from the entity. It enforces that only one camera entity is collected (though safely handles multiple candidates by iterating).

### 3. setupCameraEntity(entity) (public)
Helper function to manually trigger collection for a specific entity known to be the camera, skipping the search.

### 4. tick(deltaTime) (public)
Calculates the complete camera transformation matrix.
- Retrieves the camera's projection transform (`CameraCMP`) and world transform (`TransformCMP`).
- Inverts the camera's world transform to get the view matrix.
- Combines them to form the final View-Projection matrix.
- Updates the global `RenderEnv` with the new camera projection and view width.

## static properties
(None explicit beyond `SystemTypeName` = "CameraSetupSys")

## static functions
(None)
