# TransformCMP

This component manages the spatial state (Position, Rotation, Scale) of an entity in both Local and World space.

## associate systems
* [CameraSetupSys](../systems/camera-setup-system.md)
* [DisplaySys](../systems/display-system.md)
* [EntityMovementSys](../systems/entity-movement-system.md)
* [PatrolSys](../systems/patrol-system.md)
* [PhysicSys](../systems/physic-system.md)
* [TransformUpdateSys](../systems/transform-update-system.md)
* Virtually all systems that need position data.

## member properties
### 1. _posX, _posY, _rotate, _scaleX, _scaleY (protected)
Local transform properties relative to the parent entity.
### 2. _worldPosX, _worldPosY, ... (protected)
Cached world transform properties (absolute space). Valid only if `_isDirty` is false and parent cache is valid.
### 3. _transform, _worldTransform (protected)
Cached `love.Transform` objects for local and world matrices.
### 4. _isDirty (protected)
Flag indicating if local properties have changed and matrices need rebuilding.
### 5. _cacheID, _parentCacheID (protected)
Version counters to detect if parent transforms have changed, necessitating a world transform update.

## member functions
### 1. new() (public)
Constructor. Initialize identity transform.

### 2. setPosition, translate, setScale, setRotate (public)
Mutators for local properties. Setting these marks the component as `_isDirty`.

### 3. getTranslate_const, etc. (public)
Accessors for local properties.

### 4. getWorldPosition_const, etc. (public)
Accessors for world properties. *Note*: In Debug mode, asserts if the transform is dirty.

### 5. updateTransforms() (public)
Recursively updates the World Transform.
- Checks if parent implies an update.
- Rebuilds `_worldTransform` by combining Parent World Transform * Local Transform.
- Updates caches and clears dirty flags.

### 6. getRewindState_const(), restoreRewindState(state), lerpRewindState(a,b,t) (public)
**Time Rewind Implementation**: Supports saving and restoring transform state (currently only Scale is fully implemented in the provided code snippet, but intended for all properties).

## static properties
### 1. ComponentTypeName (public)
String identifier: "TransformCMP".
### 2. ComponentTypeID (public)
Numeric ID registered with `BaseComponent`.

## static functions
(None)
