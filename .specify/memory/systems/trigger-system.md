# TriggerSys

This system processes interaction triggers based on physics collisions.

## associate components
* [TriggerCMP](../components/trigger-component.md)

## member properties
### 1. _physicSys (private)
Reference to `PhysicSys` to retrieve collision events.

## member functions
### 1. new() (public)
Constructor. Registers requirement for `TriggerCMP`.

### 2. setPhysicSys(physicSys) (public)
Dependency injection for accessing collision events.

### 3. tick(deltaTime) (public)
- polls `_physicSys:getCollisionEvents()`.
- Filters for 'begin' collision type.
- Calls `handleCollision`.

### 4. handleCollision(entityA, entityB) (private)
- Checks if colliding entities have `TriggerCMP`.
- If so, executes the trigger callback (`executeCallback`) on the component, passing the other entity as the context.

## static properties
### 1. SystemTypeName (public)
String identifier: "TriggerSys".

## static functions
(None)
