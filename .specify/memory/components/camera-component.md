# CameraCMP

This component describes the camera's viewport properties and calculates projection matrices.

## associate systems
* [CameraSetupSys](../systems/camera-setup-system.md)

## member properties
### 1. _viewWidthMeters (protected)
The width of the camera viewport in logic units (meters).
Used by `CameraSetupSys` to configure the `RenderEnv`.
### 2. _viewHeightMeters (protected)
The height of the camera viewport in logic units (meters).
Calculated automatically based on the screen aspect ratio to maintain square pixels.

## member functions
### 1. new() (public)
Constructor.
Initializes the viewport width to 10 meters and calculates height based on the current window aspect ratio.

### 2. setViewWidthMeters(w) (public)
Sets the viewport width in meters and recalculates the height.

### 3. getViewWidthMeters_const() (public)
Returns the current viewport width in meters (read-only).

### 4. getViewHeightMeters_const() (public)
Returns the current viewport height in meters (read-only).

### 5. getProjectionTransform() (public)
Calculates and returns the projection matrix (`love.Transform`).
This matrix centers the viewport (0,0 is screen center) and scales logic units (meters) to screen pixels (PPM).

## static properties
### 1. ComponentTypeName (public)
String identifier: "CameraCMP".
### 2. ComponentTypeID (public)
Numeric ID registered with `BaseComponent`.

## static functions
(None specific)
