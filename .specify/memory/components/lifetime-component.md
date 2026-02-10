# LifeTime Component (LifeTimeCMP)

**Type**: Data Component (Gameplay/Utility)
**Source**: `Script/Component/Gameplay/LifeTimeCMP.lua`

## Purpose
Tracks how long an entity has existed and defines when it should be destroyed/expired.

## Properties
| Field | Type | Default | Description |
|---|---|---|---|
| `_maxDuration` | number | 10.0 | The total lifespan of the entity in seconds. |
| `_elapsedTime` | number | 0.0 | The time accumulated since creation. |

## Dependencies
- None.

## Usage
Attached to temporary entities (Skills, Projectiles, VFX) to automatically manage their lifecycle.
