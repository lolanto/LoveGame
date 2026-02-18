# Implementation Plan: LifeTime Component Enhancement

**Branch**: `004-lifetime-time-control` | **Date**: 2026-02-18 | **Spec**: [specs/004-lifetime-time-control/spec.md](./spec.md)
**Input**: Feature specification from `specs/004-lifetime-time-control/spec.md`

## Summary

Implement a centralized `LifeTimeSys` to manage entity duration, ensuring compatibility with `TimeManager` (scaling) and `TimeRewindSys` (restoration). Remove legacy manual checks from `BlackHoleSys`.

## Technical Context

**Language/Version**: Lua (Love2D)
**Primary Dependencies**: `BaseSystem`, `LifeTimeCMP`, `TimeManager`
**Storage**: N/A
**Testing**: Manual verification via `TestECSWorkflow` or `main` game loop.
**Target Platform**: Desktop (Windows)
**Project Type**: Game Logic (Lua)
**Performance Goals**: < 0.5ms per frame for managing < 2000 entities.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Architecture**: Follows ECS pattern (System managing Components).
- [x] **Performance**: Uses `ComponentsView` for efficient iteration.
- [x] **Maintainability**: Refactors duplicate code into a single responsibility system.

## Project Structure

### Documentation (this feature)

```text
specs/004-lifetime-time-control/
├── plan.md              # This file
├── research.md          # Architectural decisions
├── data-model.md        # Component/System schema
├── quickstart.md        # Usage guide
├── checklists/
│   └── requirements.md  # Quality checklist
└── tasks.md             # Implementation tasks
```

### Source Code

```text
Script/
├── Component/
│   └── Gameplay/
│       └── LifeTimeCMP.lua       # Existing, verify
├── System/
│   └── Gameplay/
│       ├── LifeTimeSys.lua       # NEW: Centralized logic
│       └── BlackHoleSys.lua      # UPDATE: Remove manual update
└── World.lua                     # UPDATE: Register new system? Or main.lua
```

## Phases & Tasks

### Phase 1: Implementation

1.  **Update LifeTimeCMP**
    - [ ] Edit `Script/Component/Gameplay/LifeTimeCMP.lua`.
    - [ ] Add assertions in `new(duration)`:
        - [ ] Assert `duration > 0`.
        - [ ] Assert `duration <= 3600` (1 hour limit).

2.  **Create LifeTimeSys**
    - [ ] Create `Script/System/Gameplay/LifeTimeSys.lua`.
    - [ ] Implement `point:new` and initialization with `ComponentsView`.
    - [ ] Implement `tick(deltaTime)`.
        - [ ] Check `TimeRewindSys:getIsRewinding()`. If true, return immediately.
        - [ ] Iterate `ComponentsView` for `LifeTimeCMP`. (Note: `ComponentsView` automatically excludes disabled/removed entities).
        - [ ] Calculate scaled time via `TimeManager:getDeltaTime`.
        - [ ] Update `LifeTimeCMP`.
        - [ ] Remove expired entities via `World:removeEntity`.

3.  **Register System**
    - [ ] Locate system initialization (likely `main.lua` or `World:init`).
    - [ ] Register `LifeTimeSys` in the update loop.
    - [ ] **Crucial**: Ensure `LifeTimeSys` is registered *after* `TimeRewindSys` records the frame (so recorded state is "start of frame").
    - [ ] Add `LifeTimeSys:tick` call in `World:update` inside the simulation block.

4.  **Refactor BlackHoleSys**
    - [ ] Open `Script/System/Gameplay/BlackHoleSys.lua`.
    - [ ] Remove logic that manually iterates and updates `LifeTimeCMP`.
    - [ ] Verify `BlackHoleSys` still requires `LifeTimeCMP` only if needed for other logic (e.g., visual effects based on remaining time), otherwise clean up if unused.

### Phase 2: Verification

5.  **Verify Assertions**
    - [ ] Test creating entity with duration 0 -> Expect Assert.
    - [ ] Test creating entity with duration 3601 -> Expect Assert.

6.  **Verify Time Scaling**
    - [ ] Test with `TimeManager:setTimeScale(0.1)` and `2.0`.
    - [ ] Verify paused game (scale 0) pauses lifetime.

7.  **Verify Rewind**
    - [ ] Spawn entity with short life.
    - [ ] Let it expire.
    - [ ] Rewind.
    - [ ] Verify resurrection and lifetime restoration.

## Complexity Tracking

Low complexity. Standard ECS system implementation + one refactor.
