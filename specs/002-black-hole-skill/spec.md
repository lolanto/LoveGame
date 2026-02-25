# Feature Specification: Black Hole Skill

**Feature Branch**: `002-black-hole-skill`
**Created**: 2026-02-09
**Status**: Draft
**Input**: User description: "帮我开发一个玩法功能——黑洞。这个功能让玩家可以在自身正上方3m的位置，生成一个影响半径5m的黑洞。黑洞会将周围可移动的物体吸引过来。黑洞的持续时间是10s"

## Clarifications

### Session 2026-02-14
-   Q: How should the 'T' key input be detected? → A: Input MUST be processed via `processUserInput(controller)` interface, using a `UserInteractDesc` consume info, rather than direct `love.keyboard` calls, to support uniform input management.

### Session 2026-02-16
-   Q: How should the 'Ignore List' (e.g. for the caster) identify entities? → A: Filtering MUST be performed by comparing unique Entity IDs.
-   Q: How should the gravitational force be calculated relative to object mass? → A: **Mass-Independent**; the applied force must scale with the object's mass (`F = Mass * Strength / Distance^2`) so that all objects accelerate at the same rate regardless of weight.

### Session 2026-02-22 (Interaction Mode)
-   **Updates**: Added "Interaction Mode" logic where 'O' key hold/release controls an Indicator Entity, with time-out and valid placement checks.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Interaction & Placement (Priority: P1)

As a player, I want to see a visual indicator of where the Black Hole will appear so that I can place it precisely before committing to the cooldown.

**Why this priority**: Defines the core input flow and targeting mechanism.

**Independent Test**:
1.  Hold 'O' -> Indicator appears at player position.
2.  Press Movement Keys (default WASD) -> Indicator moves within screen bounds.
3.  Release 'O' -> Black Hole spawns at Indicator position.
4.  Hold 'O' > 10s (Real Time) -> Indicator disappears, no spawn.
5.  Press Cancel Key (default ESC) during hold -> Indicator disappears, no spawn.

**Acceptance Scenarios**:

1.  **Given** the skill is ready, **When** the player presses and holds **'O'** (Configurable), **Then** the game enters "Interaction Mode" and an **Indicator Entity** spawns at the player's current position.
2.  **Given** within Interaction Mode, **When** the player presses **Movement keys** (Configurable, default WASD) (processed via `UserInteractController`), **Then** the Indicator Entity moves relative to the screen, clamped within the screen boundaries.
3.  **Given** within Interaction Mode, **When** the player **releases 'O'** while the Indicator is in a **Valid** position, **Then** the Interaction Mode ends, the Indicator is removed, and a **Black Hole Entity** spawns at the Indicator's final position.
4.  **Given** within Interaction Mode, **When** the user holds 'O' for more than **10 seconds** (Real Time), **Then** the Interaction Mode automatically ends, the Indicator is removed, and **NO** Black Hole is spawned.
5.  **Given** within Interaction Mode, **When** the player presses **Cancel Key** (Configurable, default ESC), **Then** the Interaction Mode immediately ends (Cancelled), the Indicator is removed, and **NO** Black Hole is spawned.
6.  **Given** within Interaction Mode, **When** the Indicator is in an **Invalid** position (trigger logic), **Then** its visual appearance changes (e.g., color) to indicate "Cannot Place".
7.  **Given** the Indicator is in an **Invalid** position, **When** 'O' is released, **Then** the Interaction Mode ends and **NO** Black Hole is spawned (or placement is blocked).

---

### User Story 2 - Gravitational Pull (Priority: P1)

As a player, I want the Black Hole to attract nearby objects so that they are pulled into a concentrated area.

**Why this priority**: The gameplay value comes from the interaction with other objects.

**Independent Test**: Can be tested by spawning moveables near the Black Hole and observing their movement.

**Acceptance Scenarios**:

1.  **Given** a Black Hole exists and a movable object is within the configured radius (default: 5m), **When** the game updates, **Then** the object receives a physics force directed towards the center of the Black Hole.
2.  **Given** a movable object is outside the configured radius, **When** the game updates, **Then** the object is unaffected by the Black Hole's gravity.
3.  **Given** a static object (e.g., wall, ground) within 5 meters, **When** the Black Hole is active, **Then** the static object remains in place.

## Functional Requirements *(mandatory)*

1.  **Interaction Mode Logic**:
    -   **Activation**: Triggered by pressing **Activation Key** (Configurable, default 'O', processed via `UserInteractController`). Enters "Interaction Mode".
    -   **Safety**: Must prevent "auto-restart" if the key is held down after a timeout or cancellation. The system must wait for the Activation Key to be released before accepting a new start request.
    -   **Duration**: Lasts until key release, **10s Real Time Timeout**, or **Cancel Key** (default 'ESC') cancellation.
    -   **State Tracking**: Must track "Is Placing" state and "Duration" timer.
    -   **Exit Conditions**:
        -   **Release Activation Key**: Trigger spawn attempt.
        -   **Timeout (>10s Real Time)**: Cancel interaction (cleanup Indicator, no spawn).
        -   **Press Cancel Key**: Immediate Cancel (cleanup Indicator, no spawn).
    -   **Placement Validation (Read-only)**: Interaction Mode MUST NOT drive a full physics simulation that modifies non-Indicator entities or their state. Placement validation should rely on Box2D (love.physics) read-only query interfaces (for example AABB queries via `World:queryBoundingBox`, fixture inspection, or equivalent engine queries) combined with precise geometric checks when needed. Under no circumstances should interaction-time logic call `World:update` (physics step) or otherwise mutate bodies/fixtures; validation must be read-only and side-effect free.

2.  **Input Handling**:
    -   All inputs (Activation 'O', Movement 'WASD', Cancel 'ESC') **MUST** be configurable via `Config.lua` and processed via `UserInteractController`.
    -   Direct `love.keyboard` polling is prohibited.

3.  **Indicator Entity**:
    -   **Spawning**: Created at Player's position on Interaction start.
    -   **Movement**: Controlled by **Movement Keys** (Configurable, default WASD) via Controller. Movement is confined to the **Current Player Camera Viewport** (World Space bounds visible on screen). If the user attempts to move the indicator outside, its position must be clamped to the camera's current visible rectangle.
    -   **Visuals**: Uses `DebugColorCircleCMP` to visualize the area.
    -   **Collision/Validation**:
        -   Must be a **Trigger** (Sensor) type `PhysicalCMP` + `TriggerCMP`.
        -   Must detect overlap with other objects to determine "Valid Placement" (currently defaults to "Always Valid" but interface must exist).
        -   **Visual Feedback**: Changes color/state based on validity (e.g., Green=Valid, Red=Invalid).
        -   **Interaction Mode Note**: Placement overlap detection MUST function while Interaction Mode is active. Preferred approach: use Box2D/love.physics read-only query APIs (AABB queries, fixture iteration) to collect candidate fixtures, then run precise intersection checks (circle-vs-circle, circle-vs-polygon / rect) in code. If a fallback geometric detector is required, implement reusable Rect/Circle vs Rect/Circle intersection helpers and place them under `utils/` for reuse across systems. All validation code MUST be read-only and MUST NOT modify physics state.

4.  **Black Hole Execution**:
    -   **Spawn Logic**: Only spawns if Interaction Mode ends via "Release" AND placement is "Valid".
    -   **Location**: Spawns at the **Entity Indicator's** final `Transform` position (World Space).
    -   **Parameters** (Configurable):
        -   **Radius**: 5m
        -   **Duration**: 10s (Game Time - affected by Time Dilation)
        -   **Force**: ~400 (Mass-Independent)
        -   **Trap Radius**: 0.5m

5.  **Physics Interaction (Black Hole)**:
    -   **Force Application**: Applied every physics step to dynamic objects within radius.
    -   **Formula**: `F = (ForceStrength * Mass) / Distance^2` (Inverse Square Law).
    -   **Filtering**: Support "Ignore List" via Entity ID (e.g., ignore Caster).
    -   **Trapping**: Apply simulated drag/damping when objects are very close (< 0.5m) to the center to prevent orbiting instability.

## Success Criteria *(mandatory)*

-   **Precision**: Player can successfully navigate the Indicator to a specific target on screen.
-   **Feedback**: Visuals clearly distinguish between "Aiming" (Indicator) and "Active" (Black Hole) states.
-   **Cancel**: User can cancel the skill by waiting for the timeout or pressing **Cancel Key** (default ESC).
-   **Physics**: Gravity effect works identically to previous spec.
-   **Architecture**: All inputs are decoupled from hardware via `UserInteractController`.

## Non-Functional Requirements *(Time & Physics)*

1.  **Time Rewind Interoperability**:
    -   The Black Hole entity must participate in the global Time Rewind system.
    -   **Resurrection**: If the Black Hole expires (disappears), and time is rewound to a point when it was active, it must reappear with the correct remaining duration.
    -   **State Restoration**: Its position and parameters should be consistent with the historical frame.

2.  **Time System**:
    -   **Interaction Mode**: The 10s timeout MUST be based on **Real Time** to prevent it from stalling during time stops/slows.
    -   **Black Hole Logic**: The Black Hole's duration (10s) and physics MUST be based on **Game Time** (respecting scale/dilation).
    -   **Validation Performance**: Placement validation should favor Box2D query primitives (AABB queries) for candidate filtering and only run precise geometric tests on filtered fixtures. Implementations that add pure-Lua geometric tests should place reusable helpers in `utils/` and keep them optimized.

## Key Entities & Data Models *(optional)*

-   **Indicator Entity**:
    -   `TransformCMP` (Position)
    -   `PhysicalCMP` (Sensor/Trigger Body)
    -   `TriggerCMP` (Collision Logic)
    -   `DebugColorCircleCMP` (Visual Representation)
    -   *(New)*: Logic to accept `UserInteractController` input.

-   **BlackHole Entity**:
    -   Components:
        -   `Transform` (Position)
        -   `LifeTime` (10s)
        -   `GravitationalField` (Logic/Data)
        -   `DebugColorCircle` (Visuals)

## Assumptions & Dependencies *(optional)*

-   **Input System**: `UserInteractController` supports distinguishing `KeyHeld` (for O), `AdjustedMovement` (WASD), and `KeyDown` (ESC) events.
-   **Visual Assets**: Temporary use of Debug shapes is acceptable for this phase.
-   **Coordinate System**: Screen bounds are accessible for clamping logic.
-   **Movable Objects**: Defined as entities possessing a Physics/Rigidbody component that is not Static.
