<!-- Sync Impact Report
Version Change: 1.0.0 -> 1.1.0
Modified Principles:
- I. Pure ECS Architecture: Refocused on architectural patterns; documentation rules moved to V.
Added Principles:
- V. Documentation-Driven Development: Explicit rules for consulting and updating architectural documentation.
Templates to Update:
- .specify/templates/tasks-template.md (Added specific documentation checks)
-->

# LoveGame Constitution
<!-- Project: 2D Side-Scrolling Action Adventure with Gravity & Time Control -->

## Core Principles

### I. Pure ECS Architecture (Data/Logic Separation)
**Strict Adherence to Entity-Component-System Pattern.**
*   **Components** (`Script/Component/*`) must remain **Pure Data**. They define the state but possess no behavior.
*   **Systems** (`Script/System/*`) hold all **Logic**. They operate on entities possessing specific component signatures.
*   **Entities** are merely ID containers. No "God Classes" or monolithic inheritance structures for GameObjects.
*   This project follows the ECS architecture defined in [architecture.md](./architecture.md).

### II. Time-Aware System Design
**All Systems Must Support Time Manipulation.**
*   Since "Time Control" (Rewind/Dilation) is a core selling point, every `tick(deltaTime)` function in Gameplay Systems must represent time as a variable scalar.
*   Physics and Logic updates must separate "Real Time" (UI/Menus) from "Game Time" (Level simulation).
*   State snapshots for Time Rewind must be efficient and serializable (Components must be easy to clone/serialize).

### III. Physics-First Gameplay
**Gravity & Mechanics Drive the Experience.**
*   The interaction between the player and the world is primarily through physics forces (Gravity manipulation).
*   Level design relies on "Mechanisms" (Switchers, Movers) that interact physically with the player.
*   Logic Units: Use **Meters (Standard Units)** for game logic and physics calculations, converting to Pixels only at the Rendering layer.

### IV. Modular & Compositional Design
**Entities are Assembled, Not Inherited.**
*   Behavior is defined by the aggregation of Components. What an entity is depends on what components it has.
*   Try to control the total type of components and reuse existing component as much as possible.

### V. Documentation-Driven Development
**Code and Documentation Must stay Synced.**
*   **Source of Truth**: The [architecture.md](./architecture.md) file is the authoritative guide for the project's architectural decisions. Always consult it before making structural changes.
*   **Usage Rule**: Before using a System or Component, you MUST consult its specific documentation via the index files:
    *   [architecture-systems.md](./architecture-systems.md) for Systems (e.g., using `TimeRewindSys` requires checking `time-rewind-system.md`).
    *   [architecture-components.md](./architecture-components.md) for Components.
*   **Sync Rule**: Any modification to a System or Component's logic MUST be accompanied by a simultaneous update to its corresponding documentation file in `.specify/memory/systems/` or `.specify/memory/components/`.

### VI. Modal Gameplay Architecture
**Systems Must Support Selective Execution.**
*   The game supports distinct modes (e.g., Standard Gameplay, Interaction Mode, Menus).
*   **World Pause**: In specific modes (like Interaction Mode), the main World loop pauses.
*   **Manual Ticking**: Systems initiating these modes (Initiators) effectively "take over" the game loop and must be capable of running in isolation via `tick_interaction(dt, input)` or `tick(dt)` without the rest of the world updating.
*   **Context Awareness**: Visual systems (Camera, Display) must remain active regardless of the simulation state to maintain player feedback.

## Technical Constraints & Architecture

### Technology Stack
*   **Engine**: Love2D (LÖVE) with LuaJIT.
*   **Physics Engine**: Love.physics (Box2D wrapper) for handling gravity vectors and collisions.
*   **Language Standard**: Lua 5.1/JIT compatible.

### Coordinate System & Units
*   **World System**: Right-handed Cartesian or Engine Standard (Top-Left Origin, Y-Down) consistent throughout the project.
*   **Scale**: 1 Unit = 1 Meter. Define a strict Pixel-Per-Meter (PPM) ratio in `Config.lua`.

## Development Workflow

### Code Standards
*   **Adhere to the Code Style Guide**: All code must follow the patterns defined in [code_style.md](./code_style.md), including Singleton implementation, file structure, and naming conventions.
*   **Naming**: PascalCase for Classes/Files, camelCase for variables/functions.
*   **Logging**: Use `MUtils.RegisterModule` and structured logging. `print` is forbidden.
*   **File Structure**: One Class per File. Return the Class table at the end of the file.

**Safety & Clarity over "Cleverness".**
*   **No Global Variables** leaking into the global namespace.
*   **Explicit Require**: Dependencies must be explicitly required in the file scope.
    *   **Require Paths**: The script search path includes `./Script` and `./Script/utils`. Do NOT include `Script.` or `utils.` prefixes.
    *   Example: Use `require("World")` instead of `require("Script.World")`. Use `require("ReadOnly")` instead of `require("Script.utils.ReadOnly")` or `require("utils.ReadOnly")`.
*   **Type Annotations**: Use EmmyLua/LuaLS annotations (`--- @class`, `--- @type`) to maintain code intelligence/maintainability.
*   **Defensive Checks**: Use `assert` to validate critical state assumptions (e.g., Singleton existence, Component requirement).

**Version**: 1.1.0 | **Ratified**: 2026-02-08 | **Amended**: 2026-02-15 | **Context**: 2D Action-Adventure (Gravity/Time)
