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

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Activate Black Hole (Priority: P1)

As a player, I want to be able to cast a "Black Hole" ability so that I can control the battlefield by gathering enemies or objects.

**Why this priority**: Correct triggering and spawning is the core mechanic.

**Independent Test**: Can be tested by triggering the skill and verifying the Black Hole entity appears at the correct location and persists.

**Acceptance Scenarios**:

1. **Given** the player is in a level, **When** the player activates the Black Hole skill, **Then** a Black Hole entity spawns at the configured offset (default: 3m) directly above the player's current position.
2. **Given** a Black Hole has spawned, **When** the configured duration (default: 10s) has elapsed, **Then** the Black Hole entity disappears/is destroyed.
3. **Given** the player moves, **When** the skill is activated, **Then** the Black Hole spawns relative to the player's position *at the moment of activation* (it does not follow the player unless specified).

---

### User Story 2 - Gravitational Pull (Priority: P1)

As a player, I want the Black Hole to attract nearby objects so that they are pulled into a concentrated area.

**Why this priority**: The gameplay value comes from the interaction with other objects.

**Independent Test**: Can be tested by spawning moveables near the Black Hole and observing their movement.

**Acceptance Scenarios**:

1. **Given** a Black Hole exists and a movable object is within the configured radius (default: 5m), **When** the game updates, **Then** the object receives a physics force directed towards the center of the Black Hole.
2. **Given** a movable object is outside the configured radius, **When** the game updates, **Then** the object is unaffected by the Black Hole's gravity.
3. **Given** a static object (e.g., wall, ground) within 5 meters, **When** the Black Hole is active, **Then** the static object remains in place.

---
Mechanism**: Input binding MUST be handled via the `processUserInput` interface on `BlackHoleSys`, using `UserInteractController` to consume the input state (e.g. `tryToConsumeInteractInfo`). Direct usage of `love.keyboard` is prohibited.
    -   **
## Functional Requirements *(mandatory)*

1.  **Skill Activation**:
    -   **Input**: The skill is triggered by the **'T' key** (default).
    -   **Configurability**: The input binding must be implemented to support future re-mapping (soft-coded/configurable), not hardcoded deeply in logic.
    -   Upon activation, the system must instantiate a new Black Hole entity.

2.  **Spawning Logic**:
    -   **Configuration**: The spawning offset must be a configurable parameter (Default: 3m).
    -   **Position**: The spawn position must be calculated as `PlayerPosition + (0, -SpawnOffset)` (assuming Y-up is negative for "above", or consistent with game's "up" vector).
    -   **Parenting**: The Black Hole should exist in the world space, independent of the player's subsequent movements (detached).

3.  **Black Hole Properties**:
    -   **Parameters**: The following properties must be configurable data (not hardcoded), allowing for future upgrades:
        -   **Effect Radius** (Default: 5m)
        -   **Duration** (Default: 10s)
        -   **Force Strength** (Default: 400)
        -   **Trap Radius** (Default: 0.5m)
    -   **Duration Logic**: The entity must self-destruct or deactivate after the configured duration elapses.
    -   **Visuals**: The entity must include a **Debug Visualization Component** (e.g., drawing a debug color circle) to clearly indicate its position and radius during development.

4.  **Physics Interaction**:
    -   The Black Hole must apply a force to all eligible entities within the radius each frame (or physics step).
    -   **Eligible Entities**: Entities with a dynamic physics component (movable).
    -   **Force Calculation**: A directional force vector from the object center to the Black Hole center.
    -   **Force Model**: The force must be **Mass-Independent** (simulate uniform acceleration). `AppliedForce = (ForceStrength * ObjectMass) / (DistanceSquared)`.
    -   **Force Falloff**: The force magnitude follows an Inverse Square law. It is very weak at the 5m edge and extremely strong near the center.
    -   **Capture Mechanism**: Objects within a very small radius (e.g., < 0.5m) of the center should be "trapped" to prevent orbiting or flying out due to inertia. To avoid state persistence issues (e.g. during time rewind), this must be implemented as a **Simulated Drag Force** (applying force opposite to velocity) rather than modifying the body's `LinearDamping` property.
    -   **Filtering**: The Black Hole must support an "Ignore List" containing **Entity IDs**. Specific entities (e.g., the caster/player) can be added to this list (by ID) to prevent them from being sucked in.

## Success Criteria *(mandatory)*

-   **Accuracy**: Black Hole spawns exactly at the configured offset (default 3m) from player center in the "up" direction.
-   **Range**: Objects just inside the configured radius are pulled; objects just outside are not.
-   **Timing**: Black Hole lasts exactly for the configured duration.
-   **Selectivity**: Only "movable" objects are moved; static geometry is ignored.
-   **Stability**: Captured objects settle near the center rather than slingshotting out.
-   **Safety**: The caster (Player) is not affected by their own Black Hole (verified by Entity ID).
    
    
## Non-Functional Requirements *(Time & Physics)*

1.  **Time Rewind Interoperability**:
    -   The Black Hole entity must participate in the global Time Rewind system.
    -   **Resurrection**: If the Black Hole expires (disappears), and time is rewound to a point when it was active, it must reappear with the correct remaining duration.
    -   **State Restoration**: Its position and parameters should be consistent with the historical frame.

2.  **Time Dilation (Bullet Time) Interoperability**:
    -   The Black Hole's logic (lifetime countdown, force application) must respect the Global Time Scale.
    -   When time slows down (e.g. 0.1x), the Black Hole's duration must decay 10x slower.
    -   Physics usage of DeltaTime must be scaled.

## Key Entities & Data Models *(optional)*

## Key Entities & Data Models *(optional)*

-   **BlackHole Entity**:
    -   Components:
        -   `Transform` (Position)
        -   `LifeTime` (for duration tracking)
        -   `GravitationalField` (concept/component defining radius and force strength)
        -   `DebugDraw` (or similar) to visualize position/radius

## Assumptions & Dependencies *(optional)*

-   **Measurement Unit**: The Game Engine uses Meters or a known conversion (e.g., pixel-to-meter ratio). We assume standard physics units.
-   **"Above"**: Defined as the negative Y axis (standard 2D) or opposite to gravity vector.
-   **Movable Objects**: Defined as entities possessing a Physics/Rigidbody component that is not Static.
