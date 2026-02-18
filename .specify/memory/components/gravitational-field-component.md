# Gravitational Field Component (GravitationalFieldCMP)

**Type**: Data Component (Gameplay)
**Source**: `Script/Component/Gameplay/GravitationalFieldCMP.lua`

## Purpose
Defines the parameters for a radial gravity field that attracts other physics objects.

## Properties
| Field | Type | Default | Description |
|---|---|---|---|
| `_radius` | number | 5.0 | The maximum distance (meters) where the attraction force is applied. |
| `_forceStrength` | number | 1000.0 | The base magnitude of the attraction force. |
| `_minRadius` | number | 0.5 | Minimum distance from center to prevent infinite force values (singularity protection). |

## Dependencies
- None (Pure Data).

## Usage
Attached to entities (like Black Holes) that should exert attractive forces on the environment. Used by `BlackHoleSys`.
