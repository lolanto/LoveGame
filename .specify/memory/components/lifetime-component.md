# LifeTime Component (LifeTimeCMP)

**Type**: Data Component (Gameplay/Utility)
**Source**: [Script/Component/Gameplay/LifeTimeCMP.lua](../../../Script/Component/Gameplay/LifeTimeCMP.lua)

## Purpose
Tracks how long an entity has existed and defines when it should be destroyed/expired.

## Properties
| Field | Type | Default | Description |
|---|---|---|---|
| `_maxDuration` | number | 10.0 | The total lifespan of the entity in seconds. |
| `_elapsedTime` | number | 0.0 | The time accumulated since creation. |

## Behavior

*   **Initialization**: The component asserts that the duration is strictly positive and less than or equal to 3600 seconds (1 hour). This prevents invalid configurations that could lead to immediate expiration or excessively long-lived entities.
*   **Rewind Support**: Implements `getRewindState_const` and `restoreRewindState`. This allows `TimeRewindSys` to save and restore the exact `elapsedTime` value, enabling entities to "resurrect" if time is rewound past their expiration point.
*   **System Integration**: Managed exclusively by the [LifeTimeSys](../../systems/lifetime-system.md).

## Methods

*   `addElapsedTime(dt)`: Increments `_elapsedTime`.
*   `isExpired_const()`: Returns `true` if `_elapsedTime >= _maxDuration`.
*   `getRewindState_const()`: Returns `{ elapsedTime = ... }`.
*   `restoreRewindState(state)`: Restores `_elapsedTime` from snapshot.

## Dependencies
- None.

## Usage
Attached to temporary entities (Skills, Projectiles, VFX) to automatically manage their lifecycle.
