# Black Hole System (BlackHoleSys)

**Type**: Gameplay System
**Source**: `Script/System/Gameplay/BlackHoleSys.lua`

## Purpose
Manages the lifecycle, input triggering, and physics interaction of Black Hole entities.

## Logic Flow
1. **Input Handling**: Listens for 'T' key to spawn a Black Hole entity above the player.
2. **Lifecycle Management**: Updates `LifeTimeCMP` on Black Hole entities and destroys them when expired.
3. **Physics Interaction**: Iterates over relevant physics entities and applies an attractive force towards active Black Holes based on `GravitationalFieldCMP` parameters.

## Component Requirements
- `GravitationalFieldCMP`
- `LifeTimeCMP`
- `TransformCMP`

## External Dependencies
- `PhysicSys`: Required to access the physics world and apply forces to bodies.
