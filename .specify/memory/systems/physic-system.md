# PhysicSys

This system manages the Box2D physics world simulation and synchronizes state between Physics bodies and Entity transforms.

## associate components
* [PhysicCMP](../components/physic-component.md)
* [TransformCMP](../components/transform-component.md)

## member properties
### 1. _world (private)
The `love.physics.World` instance. Gravity is set to (0, 9.8).

### 2. _collisionEvents (private)
A list of collision events that occurred in the current frame.

## member functions
### 1. new() (public)
Constructor.
- Registers requirements for `PhysicCMP` and `TransformCMP`.
- Initializes the physics world.
- Sets up collision callbacks to populate `_collisionEvents`.

### 2. getCollisionEvents() (public)
Returns the list of collision events processed in the current frame.

### 3. getWorld() (public)
Returns the internal Box2D world object.

### 4. tick(deltaTime) (public)
Main physics update loop.
1.  **Sync Transform -> Physics**: Updates Body position/rotation from `TransformCMP` (for Kinematic/Static bodies or teleports).
2.  **Time Dilation Handling**:
    - Calculates `physicsDt` based on global time scale.
    - Handles "Exception Entities" (entities ignoring time scale):
        - Scales velocity up (`v / scale`).
        - Applies gravity compensation force (`F = m * g * (1/scale - 1)`).
3.  **Simulation**: Calls `_world:update(physicsDt)`.
4.  **Restore Velocities**: Reverts velocity scaling for exception entities (`v * scale`).
5.  **Sync Physics -> Transform**: Updates `TransformCMP` position/rotation from Body (for Dynamic bodies).

## static properties
### 1. SystemTypeName (public)
String identifier: "PhysicSys".

## static functions
(None)
