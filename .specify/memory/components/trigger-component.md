# TriggerCMP

This component acts as a callback hook for physics interactions. It allows gameplay code to react when the entity collides with something.

## associate systems
* [TriggerSys](../systems/trigger-system.md)

## member properties
### 1. _callback (protected)
A function `fun(selfEntity, otherEntity)` to be executed on collision.

## member functions
### 1. new() (public)
Constructor.

### 2. setCallback(fn) (public)
Sets the trigger callback.

### 3. getCallback() (public)
Returns the callback.

### 4. executeCallback(otherEntity) (public)
Called by `TriggerSys` on collision events. Invokes the stored callback with the colliding entity.

## static properties
### 1. ComponentTypeName (public)
String identifier: "TriggerCMP".
### 2. ComponentTypeID (public)
Numeric ID registered with `BaseComponent`.

## static functions
(None)
