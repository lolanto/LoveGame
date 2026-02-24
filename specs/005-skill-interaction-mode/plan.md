# Implementation Plan - Skill Interaction Mode

**Branch**: `005-skill-interaction-mode` | **Date**: 2026-02-20 | **Spec**: [specs/005-skill-interaction-mode/spec.md](specs/005-skill-interaction-mode/spec.md)
**Input**: Feature specification from `specs/005-skill-interaction-mode/spec.md`

## Summary

Implement a dedicated "Interaction Mode" that pauses standard gameplay (physics, AI, time) while allowing specific systems (Skill Targeting) to run freely. This involves:
1.  Creating a `InteractionManager` singleton to coordinate state.
2.  Extending `World` with generic system pause capabilities.
3.  Utilizing `InteractionManager` to control system states (Pause/Resume).
4.  Implementing a reference/test system to validate the interaction loop.

## Technical Context

**Language/Version**: Lua 5.1 (LuaJIT)
**Primary Dependencies**: `Love2D`, `MUtils`, `TimeManager`, `World`
**Storage**: N/A
**Testing**: Manual testing via `TestECSWorkflow.lua` and new debugging system.
**Target Platform**: Windows
**Project Type**: Single-player Game
**Performance Goals**: Instant pause/resume (<16ms transition).
**Constraints**: Must override Time Rewind functionality. Physics state must be perfectly preserved.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

*   [x] **I. Pure ECS Architecture**: Interaction Logic separated into `InteractionManager` (Logic) and specific usage via Systems. State is clean.
*   [x] **II. Time-Aware System Design**: Explicitly addresses Time Scaling (0 scale for pause) and Real Time vs Game Time.
*   [x] **III. Physics-First Gameplay**: Physics is explicitly paused and resumed deterministically.
*   [x] **IV. Modular & Compositional Design**: Uses Event-Driven architecture (`Event_InteractionStarted`) to decouple systems.
*   [x] **V. Documentation-Driven Development**: All specs and plans are documented in `specs/`.

## Project Structure

### Documentation (this feature)

```text
specs/005-skill-interaction-mode/
├── plan.md              # This file
├── research.md          # Generated
├── data-model.md        # Generated
├── quickstart.md        # Generated
├── contracts/           # Generated
│   ├── InteractionManager.lua
│   └── EventInterfaces.lua (Snippets)
└── tasks.md             # To be generated
```

### Source Code

```text
Script/
├── InteractionManager.lua       # NEW: Core Logic
├── EventInterfaces.lua          # MODIFIED: New keys
├── World.lua                    # MODIFIED: Generic pausing logic
├── main.lua                     # MODIFIED: Ticking InteractionManager
├── UserInteractController.lua   # MODIFIED: Input blocking (Plan Check)
├── System/
│   └── Tests/
│       └── TestInteractionSys.lua # NEW: Verification System
```

## Phase 1: Core Logic Implementation

**Goal**: Implement the state machine and pausing mechanism.

1.  **InteractionManager**: Create the Singleton class based on `data-model.md`.
    *   State: `_isActive`, `_initiator`, `_timeout`.
    *   Methods: `requestStart`, `requestEnd`, `tick(dt, userInteractController)`.
2.  **Events**: Define `Event_InteractionStarted` / `Event_InteractionEnded` in `InteractionManager.lua`.
    *   **Payload**: Must include `{ initiator = systemInstance }`.
    *   **Usage**: Systems consuming this event must check `if payload.initiator == self` to distinguish their own interaction requests from others.
3.  **World Integration**:
    *   **Refactor `World:update(dt)`**:
        *   Add a check at the beginning: `if InteractionManager.getInstance():isActive() then return end` (or allow `InteractionManager` to block it).
        *   **CRITICAL**: This ensures the standard game loop is completely paused without modifying every single system.
    *   **External Control**:
        *   Ensure `World` exposes `getSystem(name)` so `InteractionManager` can retrieve and tick specific systems manually during the interrupted state.

4.  **InteractionManager Control**:
    *   **Tick Logic**:
        *   `InteractionManager:tick(dt, userInteractController)` is called from `main.lua` (or `love.update`).
        *   **IF Active**:
            *   It effectively *takes over* the game loop.
            *   It performs `world:clean()` to handle entity removals.
            *   It manually calls `system:tick(dt)` for essential systems: `TransformUpdateSys`, `CameraSetupSys`, and `DisplaySys`.
            *   **Crucial Update**: `DisplaySys` must be modified to check `InteractionManager:isActive()` before calling `AnimationCMP:update()`. This ensures animations freeze while rendering continues.
            *   It manually calls `system:processUserInput(userInteractController)` then `system:tick_interaction(dt)` (or standard `tick`) for the *Initiator*.
            *   **New Requirement**: Systems intended to run during interaction (like the Initiator) should implement a specific `tick_interaction(dt)` (or be designed to handle their standard `tick` correctly in isolation).
    *   **System Design**:
        *   Standard Systems (`PhysicSys`, etc.) do **NOT** need `isActive()` checks because `World:update` is skipped entirely.
        *   Allowed Systems (Initiator) are driven explicitly by `InteractionManager`.

5.  **Input Blocking & Management**:
    *   **Dependency**: `InteractionManager` depends on `UserInteractController` to determine input state or suppress inputs.
    *   **Logic**: `InteractionManager` may query `UserInteractController` to check for specific interaction inputs, or `UserInteractController` updates its state based on `InteractionManager:isActive()` to block standard gameplay inputs.
    *   **Action**: Pass `UserInteractController` to `InteractionManager:tick(dt, userInteractController)` in `main.lua`.

## Phase 2: Verification & UI

**Goal**: Validate the feature with a visible test case.

1.  **Test System**: Create `TestInteractionSys.lua`.
    *   Listen for `K` key (Interact).
    *   Call `InteractionManager:requestStart`.
    *   Draw a circle at mouse position (Indicator).
    *   Release `K` -> `requestEnd`.
2.  **UI Overlay**:
    *   Implement a simple `love.graphics.rectangle` overlay in `InteractionManager:draw`.
    *   Update `main.lua` to call `InteractionManager:draw()` after `World:draw()`.
    *   Text: "INTERACTION MODE".
3.  **Refinement**:
    *   Ensure Time Rewind is disabled/paused during interaction.

## Phase 3: Integration (Post-Feature)

*   Integrate with `BlackHoleSys` (in separate task/feature or as verify step).
*   Integrate with `Time-Rewind` to ensure history isn't recorded.

