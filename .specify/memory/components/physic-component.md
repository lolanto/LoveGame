# PhysicCMP

This component binds a Logical Entity to a Box2D Physics Body.

## associate systems
* [PhysicSys](../systems/physic-system.md)
* [PhysicVisualizeSys](../systems/physic-visualize-system.md)
* [TriggerSys](../systems/trigger-system.md) (via collision events)

## member properties
### 1. _body (protected)
The `love.physics.Body` instance.
### 2. _fixture (protected)
The `love.physics.Fixture` instance. Attached to the body.
### 3. _shape (protected)
A logic-layer wrapper (`Shape` object) describing the geometry (Circle or Rectangle) and density.
### 4. _world (protected)
Reference to the `love.physics.World`.

## member functions
### 1. new(world, opts) (public)
Constructor.
- Creates a Box2D Body (Static, Dynamic, or Kinematic).
- Creates a Box2D Shape based on `opts.shape` (Circle/Rectangle) descriptors.
- Creates a Box2D Fixture.

### 2. onBound(entity) (public)
Lifecycle hook. Sets the UserData of the Box2D Fixture and Body to point back to the Entity.

### 3. onUnbound() (public)
Lifecycle hook. Clears UserData references. Note: Destroying the Box2D body is usually handled by keeping the world clean or explicit destruction logic (TODO).

## static properties
### 1. ComponentTypeName (public)
String identifier: "PhysicCMP".
### 2. ComponentTypeID (public)
Numeric ID registered with `BaseComponent`.

## static functions
(None)
