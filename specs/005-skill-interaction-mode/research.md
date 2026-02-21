# Research: Skill Interaction Mode

## Architecture

This feature requires a "Global Pause" state where specific game logic (Skill Targeting) continues to run while the rest of the world (including Physics and existing Entities) is frozen.

### 1. Game Loop & Time Management
The current `World:update(dt)` iterates over hardcoded systems. `TimeManager` controls global time scale.
*   **Approach**: We will use `TimeManager` to set the global time scale to 0. This effectively pauses all systems that rely on `TimeManager:getDeltaTime(dt)` or use physics.
*   **Exception Handling**: The systems that need to run (e.g., the Skill System logic handling the targeting) will access the raw `dt` (Real Time) via `World:update`. The specific logic *inside* these systems must be aware of the "Interaction Mode" context to use `realDt` instead of `gameDt`.
    *   Actually, `World` passes `dt` (Real Time) to `tick`. Systems call `tm:getDeltaTime(dt, entity)`.
    *   If `tm:setTimeScale(0)`, then `gameDt` is 0.
    *   We need the "Interaction Logic" (e.g., updating the indicator position) to use `dt` directly, bypassing `TimeManager` or using a specific "Interaction Time" context.
    *   Since the Indicator is likely an Entity, if we want it to animate, we might need it to be an "Exception Entity" in `TimeManager`. `entity:isTimeScaleException_const()` exists.

### 2. Interaction Manager
We need a centralized manager to handle the state transitions.
*   **Module**: `Script/InteractionManager.lua` (Singleton)
*   **Responsibilities**:
    *   Track `_isActive`, `_initiatorSystem`.
    *   Handle `requestStart` and `requestEnd`.
    *   Dispatch `Event_InteractionStarted` / `Event_InteractionEnded`.
    *   Handle Timeout.
    *   Manage "Input Consumption" priority.

### 3. Visuals & UI
*   **Overlay**: A simple full-screen rectangle with low alpha. Rendered by a new simple system or `DisplaySys` hook.
*   **Indicators**: The specific Skill System (e.g., `BlackHoleSys`) will create "Indicator Entities" or draw directly during the interaction phase.
*   **Text**: "INTERACTION PROCEEDING".

### 4. Input Handling
*   **Conflict**: Normal game input (WASD) must be disabled.
*   **Solution**: `InteractionManager` will signal `UserInteractController` or `MainCharacterInteractSys` to suppress standard input.
*   **Mechanism**: A flag in `UserInteractController` or simply "consuming" the input in the Interaction logic before others see it. The current `UserInteractController` supports consumption. We just need to ensure the Interaction logic runs *first* or has priority.

## Decision Log

### Decision 1: Use `TimeManager` for Pausing
*   **Rationale**: The engine already supports time scaling. Setting scale to 0 is the cleanest way to pause physics and game logic without hacking the `World` loop too much.
*   **Impact**: Gravity, Physics, AI, and Lifetime management will automatically pause.
*   **Caveat**: We must ensure the "Interaction Indicator" entities are marked as `TimeScaleException` so they can animate/move during the pause.

### Decision 2: InteractionManager Singleton
*   **Rationale**: Decouples the "Pause/Resume" logic from specific skills. Allows any system to request a "Targeting Mode".
*   **Alternatives**: Implementing ad-hoc pausing in `World.lua`. Rejected for maintainability.

### Decision 3: Event-Driven Communication
*   **Rationale**: Systems shouldn't hard-depend on each other. `Event_InteractionStarted` allows the UI/Camera/Audio to react without direct calls.

## Clarifications Resolved
*   **Update Loop**: We won't change the `World` loop structure. We'll rely on `TimeManager` scaling to 0.
*   **Rendering**: `DisplaySys` continues to run. Since physics sets positions, and physics is paused, everything stays still.
*   **Inputs**: We will add a check in `MainCharacterInteractSys` to ignore input if `InteractionManager:isActive()`.

