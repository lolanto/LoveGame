# Implementation Plan - Black Hole Skill

**Feature Branch**: `002-black-hole-skill`
**Feature Spec**: [spec.md](spec.md)

## Technical Context

### System Analysis

-   **Existing Systems**:
    -   `InteractionManager`: Manages exclusive interaction modes, pausing the world loop and delegating ticks.
    -   `UserInteractController`: Handles input state (KeyHeld, KeyReleased, KeyDown).
    -   `PhysicSys`: Manages the Box2D world.
    -   `BaseSystem`: Parent for all systems.
    -   `LevelManager`: Manages entities.

-   **Architecture Fit**:
    -   **Pure ECS**: We will add `GravitationalFieldCMP` (Data) and `BlackHoleSys` (Logic).
    -   **Interaction Mode**: `BlackHoleSys` will utilize `InteractionManager` to request an exclusive interaction state.
        -   Start: 'O' key triggers `InteractionManager:requestStart`.
        -   Loop: `BlackHoleSys:tick_interaction` handles the aiming logic.
        -   End: `InteractionManager:requestEnd` handles cleanup.
    -   **Physics**: We will use `love.physics.Body:applyForce` with **Mass-Independent** calculation (`F = m*a`).
    -   **Input**: `BlackHoleSys` detects 'O' release inside `tick_interaction` to spawn.

### Codebase Map

-   `Script/Component/Gameplay/GravitationalFieldCMP.lua` (New): Data for black hole.
-   `Script/Component/DrawableComponents/DebugColorCircleCMP.lua`: Existing, for visuals.
-   `Script/System/Gameplay/BlackHoleSys.lua` (New): Logic for interaction state, spawning and force application.
-   `Script/Component/TransformCMP.lua`: Position.
-   `Script/Component/PhysicCMP.lua`: To indentify physics entities.
-   `Script/Component/Gameplay/TriggerCMP.lua`: For Indicator Entity overlap detection.

## Constitution Check

### Core Principles

-   [ ] **Pure ECS**: `GravitationalFieldCMP` will only contain radius, force, duration. No methods. `BlackHoleSys` will handle logic.
-   [ ] **Time-Aware**: `BlackHoleSys` must use `dt` (delta time) for duration counting. **Interaction Timeout** uses Real Time.
-   [ ] **Physics-First**: We are applying physics forces.
-   [ ] **Mass-Independent**: Force calculation must account for object mass to ensure uniform acceleration.
-   [ ] **Modular**: Black Hole is an entity composed of `TransformCMP`, `GravitationalFieldCMP`, `DebugColorCircleCMP`.

## Gates

-   [ ] **Gate 1**: Can we spawn an entity dynamically? *Yes.*
-   [ ] **Gate 2**: Can we query all physical entities efficiently? *Need to verify in Phase 0.*
-   [ ] **Gate 3**: Can we apply forces to Box2D bodies? *Yes.*
-   [ ] **Gate 4**: Can we capture WASD input via UserInteractController? *Yes, `tryToConsumeInteractInfo` supports querying specific key states.*

## Phases

### Phase 0: Research (Validation)

-   [x] **Goal**: Resolve "How to access all physics entities from `BlackHoleSys`".
    -   **Result**: Inject `PhysicSys` into `BlackHoleSys` and read `_collectedComponents['PhysicCMP']`.
    -   See [research.md](research.md).

### Phase 1: Design & Contracts

-   [x] **Data Model**: `GravitationalFieldCMP` structure defined in [data-model.md](data-model.md).
-   [x] **API**: Input configuration defined in `Config.lua`.
-   [x] **Input**: Strategy defined (`processUserInput`).

### Phase 2: Implementation

1.  **Create Components**: `GravitationalFieldCMP`, `LifeTimeCMP` (if not exists).
2.  **Create System**: `BlackHoleSys`.
    -   **State Management (via InteractionManager)**:
        -   Start: In `processUserInput`, Ensure key state is valid (wait for release if previously held) -> `InteractionManager:requestStart(self, timeout)`.
        -   Loop: Implement `BlackHoleSys:tick_interaction(dt, inputController)`.
        -   End: Call `InteractionManager:requestEnd('Spawn'|'Cancel'|'Timeout')`.
    -   **Interaction Logic (inside `tick_interaction`)**:
        -   **Spawn State**: When starting, create Indicator Entity.
        -   **Aiming**: 
            -   Read Movement Inputs (Configurable, e.g. WASD) via `inputController` -> Move Indicator.
            -   **Clamping**: Keep Indicator within Camera Viewport (using `RenderEnv`).
            -   **Validation**: Register a callback in `TriggerCMP` to handle intersection tests (detecting 'Static' geometry). The `BlackHoleSys` will check the state updated by this callback to toggle visual state (Green/Red), instead of manually iterating contacts in the System.
        -   **Completion**:
            -   If Trigger Key ('O') Released -> Spawn Black Hole at Indicator -> Request End ('Spawn').
            -   If Cancel Key (Configurable, e.g. 'ESC') Pressed -> Destroy Indicator -> Request End ('Cancel').
    -   **Physics Logic**:
        -   `tick(dt)`: Standard ECS update for existing Black Holes (Gravity).
        -   `applyAttraction`: Loop through physics entities.
        -   **Filter**: Ignore `_ignoreEntities` (by Entity ID).
        -   **Force**: Apply `(Strength * Mass) / Distance^2`.
3.  **Integration**:
    -   Add `BlackHoleSys` to `main.lua`.
    -   Inject `PhysicSys` into `BlackHoleSys`.
    -   Add `Config` entries for Keys ('O') and Params.


## Needs Clarification
-   How to iterate *other* entities inside a System? (Will research in Phase 0).
