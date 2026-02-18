# LoveGame Constitution
<!-- Project: 2D Side-Scrolling Action Adventure with Gravity & Time Control -->

## Core Principles

### I. Pure ECS Architecture (Data/Logic Separation)
**Strict Adherence to Entity-Component-System Pattern.**
*   **Components** (`Script/Component/*`) must remain **Pure Data**. They define the state but possess no behavior.
*   **Systems** (`Script/System/*`) hold all **Logic**. They operate on entities possessing specific component signatures.
*   **Entities** are merely ID containers. No "God Classes" or monolithic inheritance structures for GameObjects.
*   This project follows the ECS architecture defined in [architecture.md](./architecture.md).
*   This document [architecture-components.md](./architecture-components.md) is an index of all existing components. Update this document every time a component been created or removed.
*   Detail of each component is stored under folder of `./specify/memory/components`. Every time the implementation of a component is updated, the corresponding document should be updated at the same time.
*   This document [architecture-systems.md](./architecture-systems.md) is an index of all existing systems. Update this document every time a system been created or removed.
*   Detail of each system is stored under folder of `./specify/memory/systems`. Every time the implementation of a system is updated, the corresponding document should be updated at the same time.

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
*   **Naming**: PascalCase for Classes/Files, camelCase for variables/functions.
*   **Logging**: Use `MUtils.RegisterModule` and structured logging. `print` is forbidden.
*   **File Structure**: One Class per File. Return the Class table at the end of the file.

**Safety & Clarity over "Cleverness".**
*   **No Global Variables** leaking into the global namespace.
*   **Explicit Require**: Dependencies must be explicitly required in the file scope.
*   **Type Annotations**: Use EmmyLua/LuaLS annotations (`--- @class`, `--- @type`) to maintain code intelligence/maintainability.
*   **Defensive Checks**: Use `assert` to validate critical state assumptions (e.g., Singleton existence, Component requirement).

**Version**: 1.0.0 | **Ratified**: 2026-02-08 | **Context**: 2D Action-Adventure (Gravity/Time)
