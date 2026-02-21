# Data Model: Skill Interaction Mode

## Core Components

### 1. InteractionManager (Singleton)
Manages the global interaction state, timeout, and event dispatching.

| Field | Type | Description |
|---|---|---|
| `_isActive` | `boolean` | Is interaction mode currently active? |
| `_initiatorSystem` | `System` | The system that requested the interaction (e.g., `BlackHoleSys`). |
| `_timeout` | `number` | Maximum duration in seconds before auto-cancel. |
| `_elapsed` | `number` | Time elapsed since interaction started. |
| `_context` | `table` | Optional context data passed by the initiator. |

| Method | Returns | Description |
|---|---|---|
| `getInstance()` | `InteractionManager` | Singleton access. |
| `requestStart(system, config)` | `boolean` | Request to enter interaction mode. `config` includes `timeout`. |
| `requestEnd(reason)` | `void` | End interaction mode manually. `reason`: "Manual", "Timeout", "Cancel". |
| `isActive()` | `boolean` | Check if active. |
| `tick(dt)` | `void` | Update timer and check timeout. |

### 2. Events (Defined in InteractionManager)

| Event Name | Payload | Description |
|---|---|---|
| `Event_InteractionStarted` | `{ initiator: System, context: table }` | Fired when mode begins. Listeners (e.g., UI, Camera) should prepare. |
| `Event_InteractionEnded` | `{ initiator: System, reason: string }` | Fired when mode ends. Initiator should execute skill or cleanup. |

### 3. World Integration
`World` will not store state but will update `InteractionManager`.
It will also modify `TimeManager` context based on interaction state.

## Systems Update Strategy

*   **Standard Systems**: `PhysicSys`, `EntityMovementSys`, `PatrolSys` etc.
    *   Receiver: `TimeManager:getDeltaTime(dt)` -> **0**.
    *   Result: Frozen.
*   **Interaction Logic**: Inside `InitiatorSystem:processUserInput`.
    *   Receiver: Raw `dt` (Real Time) passed from `World`.
    *   Result: Input processed, internal timers update manually.
*   **Indicator Entities**:
    *   Component: `TimeScaleExceptionCMP` (Conceptual) or `entity:setTimeScaleException(true)`.
    *   Receiver: `TimeManager:getDeltaTime(dt, entity)` -> **Real Time**.
    *   Result: Animated/Moving indicators.

