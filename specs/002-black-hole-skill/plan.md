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
    -   **Physics**: We will use `love.physics.Body:applyForce`.
    -   **Input**: We'll need to check for 'T' key press.

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
-   [ ] **Modular**: Black Hole is an entity composed of `TransformCMP`, `GravitationalFieldCMP`, `DebugColorCircleCMP`.

## Gates

-   [ ] **Gate 1**: Can we spawn an entity dynamically? *Yes.*
-   [ ] **Gate 2**: Can we query all physical entities efficiently? *Need to verify in Phase 0.*
-   [ ] **Gate 3**: Can we apply forces to Box2D bodies? *Yes.*

## Phases

### Phase 0: Research (Validation)

-   [ ] **Goal**: Resolve "How to access all physics entities from `BlackHoleSys`".
    -   Systems usually process *their* entities. `BlackHoleSys` owns "Black Holes". It acts *on* "Physical Entities".
    -   Need to check if `LevelManager` or a shared resource allows querying other components.

### Phase 1: Design & Contracts

-   [ ] **Data Model**: `GravitationalFieldCMP` structure with strict types.
-   [ ] **API**: Input configuration.

### Phase 2: Implementation

1.  **Create Components**: `GravitationalFieldCMP`.
2.  **Create System**: `BlackHoleSys`.
    -   Handle 'T' input (spawn).
    -   Handle Lifecycle (duration).
    -   Handle Physics (force application).
3.  **Integration**: Add to `Config.lua` or system loader.

## Needs Clarification
-   How to iterate *other* entities inside a System? (Will research in Phase 0).
