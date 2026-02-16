# Implementation Plan - Black Hole Skill

**Feature Branch**: `002-black-hole-skill`
**Feature Spec**: [spec.md](spec.md)

## Technical Context

### System Analysis

-   **Existing Systems**:
    -   `UserInteractController`: Handles input state.
    -   `PhysicSys`: Manages the Box2D world.
    -   `BaseSystem`: Parent for all systems.
    -   `LevelManager`: Manages entities.

-   **Architecture Fit**:
    -   **Pure ECS**: We will add `GravitationalFieldCMP` (Data) and `BlackHoleSys` (Logic).
    -   **Physics**: We will use `love.physics.Body:applyForce` with **Mass-Independent** calculation (`F = m*a`).
    -   **Input**: Implement `processUserInput` to consume 'T' key press via `UserInteractController`.

### Codebase Map

-   `Script/Component/Gameplay/GravitationalFieldCMP.lua` (New): Data for black hole.
-   `Script/System/Gameplay/BlackHoleSys.lua` (New): Logic for spawning and force application.
-   `Script/Component/TransformCMP.lua`: Position.
-   `Script/Component/PhysicCMP.lua`: To indentify physics entities.

## Constitution Check

### Core Principles

-   [ ] **Pure ECS**: `GravitationalFieldCMP` will only contain radius, force, duration. No methods. `BlackHoleSys` will handle logic.
-   [ ] **Time-Aware**: `BlackHoleSys` must use `dt` (delta time) for duration counting.
-   [ ] **Physics-First**: We are applying physics forces.
-   [ ] **Mass-Independent**: Force calculation must account for object mass to ensure uniform acceleration.
-   [ ] **Modular**: Black Hole is an entity composed of `TransformCMP`, `GravitationalFieldCMP`, `DebugColorCircleCMP`.

## Gates

-   [ ] **Gate 1**: Can we spawn an entity dynamically? *Yes.*
-   [ ] **Gate 2**: Can we query all physical entities efficiently? *Need to verify in Phase 0.*
-   [ ] **Gate 3**: Can we apply forces to Box2D bodies? *Yes.*

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

1.  **Create Components**: `GravitationalFieldCMP`, `LifeTimeCMP` (if not exists), `DebugColorCircleCMP`.
2.  **Create System**: `BlackHoleSys`.
    -   Implement `processUserInput(controller)` for 'T' key detection.
    -   Implement `tick(dt)` for validity check & force application.
    -   Implement `applyAttraction` using `physicsSys` list.
        -   **Filter**: Ignore `_ignoreEntities` (by Entity ID).
        -   **Force**: Apply `(Strength * Mass) / Distance^2`.
3.  **Integration**:
    -   Add `BlackHoleSys` to `main.lua`.
    -   Inject `PhysicSys` into `BlackHoleSys`.
    -   Add `Config` entries.


## Needs Clarification
-   How to iterate *other* entities inside a System? (Will research in Phase 0).
