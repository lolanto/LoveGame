# Data Model: Black Hole Skill

**Component: `GravitationalFieldCMP`**

| Field | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `_radius` | number | 5.0 | The maximum distance (meters) where the attraction force is applied. |
| `_forceStrength` | number | 400.0 | The base magnitude of the attraction force. (Lowered from 1000) |
| `_minRadius` | number | 0.5 | Minimum distance to avoid infinite force at singularity. Also used as "Trap" radius. |
| `_ignoreEntities` | table | {} | List (Set) of Entity IDs to ignore during force calculation. |

**Component: `LifeTimeCMP` (Generic)**
| Field | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `_duration` | number | 10.0 | Total lifetime (seconds). |
| `_elapsed` | number | 0.0 | Time passed. |

**Entity Composition: "Black Hole"**
*   `TransformCMP`
*   `GravitationalFieldCMP` (Radius=5, Strength=400, Ignore={SourceEntity})
*   `LifeTimeCMP` (Duration=10)
*   `DebugColorCircleCMP`

**Storage Format**
*   Lua Class.
