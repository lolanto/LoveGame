# Feature Specification: Skill Interaction Mode

**Feature Branch**: `005-skill-interaction-mode`  
**Created**: 2026-02-18  
**Status**: Draft  
**Input**: User description: "Implement a new interaction logic for skill release where users specify location/direction. The game logic pauses during this mode, and it is invisible to time rewind."

## Clarifications

### Session 2026-02-20
- **Input Conflicts**: Interaction Mode overrides standard gameplay inputs. WASD (Movement), Backspace (Rewind), Left Ctrl (Bullet Time), and T (Skill Trigger) are consumed or disabled. The specific skill system defines new behavior for these inputs.
- **Priority**: Interaction Mode supersedes Time Rewind. If mode starts during rewind, rewind stops. Rewind is unavailable during mode.
- **Game Logic**: Damage calculation and death processing are paused until mode exit.
- **UI**: Placeholder support for UI changes; specifics deferred to future UI system.
- **Time Rewind Integration**: "Skipping" means no frames recorded. No RNG in rewind (deterministic state replay). Rewind history clear on game load is standard behavior, unaffected by mode.
- **Success/Failure**: Mode only manages start/end events. Success/failure/cancellation logic resides in the specific skill system.
- **Timeout**: Timeout acts identically to manual exit, triggering the end event.
- **Cooldowns**: Managed by the initiating skill system before requesting mode entry.
- **Camera**: Locked to player (static) as movement is disabled.
- **Visuals**: Placeholder interfaces for visual effects (e.g., time freeze) required.
- **Rendering**: Indicators share global Z-order. Off-screen visibility handled by skill system.
- **Physics**: Resumes exactly from pre-interaction state.
- **Dynamic Updates**: The specific skill system requesting the mode is added to the dynamic update allowlist.
- **Exit Reason**: The `Event_InteractionEnded` must carry a flag indicating the cause (Timeout vs Manual Release).
- **Player Invulnerability**: The Player entity cannot be destroyed or take damage during Interaction Mode; all damage processing is paused.
- **Snapshot Timing**: A `TimeRewind` snapshot must be recorded immediately upon resuming normal gameplay to prevent history gaps.
- **Error Safety**: If an allowed system throws an error during the paused state, the application should assert/fail fast to prevent "phantom" states.
- **System Inteference**: Opening a system menu (e.g., `Esc`, `Tab`) suspends the Interaction Mode; aiming resumes from the exact state upon menu closure.
- **Visual Placeholder**: The active state must be indicated by a full-screen overlay (e.g., 50% opacity color) and a text label "INTERACTION PROCEEDING".

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Enter and Exit Targeting Mode (Priority: P1)

As a player, I want the game action to freeze when I hold the skill button, allowing me to aim my skill without time pressure.

**Why this priority**: Core functionality of the feature. Without pausing, the targeted skill mechanism doesn't work as intended.

**Independent Test**: Can be tested by assigning a debug key to trigger the mode and verifying that moving entities stop while the key is held.

**Acceptance Scenarios**:

1. **Given** the player is in normal gameplay and enemies are moving, **When** the player holds the skill trigger button (e.g., 'T'), **Then** the game enters 'Interaction Mode' and all enemy movement/physics stops.
2. **Given** the game is in 'Interaction Mode', **When** the player releases the skill trigger button, **Then** the game resumes normal logic and enemies continue moving.
3. **Given** the game is in 'Interaction Mode', **When** the player holds the button for longer than the maximum timeout (if configured), **Then** the mode automatically exits.

---

### User Story 2 - Skill-Specific Behavior & Aiming (Priority: P1)

As a player, I want to see a target indicator (or other skill-specific visuals) and control it while the game is paused, so I can precisely aim my capability.

**Why this priority**: Essential for the player to know where the skill will be cast.

**Independent Test**: Can be tested by creating a dummy "Test Skill System" that listens for interaction events and draws a simple circle that follows the mouse/keyboard input when active.

**Acceptance Scenarios**:

1. **Given** the 'Interaction Mode' is active and a specific skill is selected, **When** the mode sends the 'Enter' signal, **Then** the specific skill system receives control to render its own specific indicator (e.g., a crosshair, an arrow, or an area of effect).
2. **Given** the 'Interaction Mode' is active, **When** the main game loop is paused, **Then** the selected skill system is still allowed to update (tick) to process input and animate its indicator.
3. **Given** the player releases the trigger button, **When** the mode sends the 'Exit' signal, **Then** the specific skill system validates its state and executes the skill if valid.

---

### User Story 3 - Time Rewind Exclusion (Priority: P2)

As a player, I want my aiming process to be ignored by the time rewind mechanic, so that rewinding doesn't force me to watch the aiming sequence again.

**Why this priority**: Ensures the time rewind mechanic feels consistent and doesn't break the flow of combat.

**Independent Test**: Record a session where targeting mode is used, then trigger time rewind and verify the targeting phase is skipped.

**Acceptance Scenarios**:

1. **Given** the player spends 5 seconds aiming a skill in 'Interaction Mode', **When** the player later uses Time Rewind, **Then** these 5 seconds are not replayed; the skill cast appears instantaneous in the timeline.
2. **Given** the 'Interaction Mode' is active, **When** the player performs actions, **Then** these actions constitute a single atomic state change in the recorded history.

## Functional Requirements *(mandatory)*

### Interaction Logic
- **Start Condition**: Triggered by user input (e.g., specific Key Down 'T').
  - Must dispatch an `Event_InteractionStarted` message.
  - Must notify the *active skill system* causing the Interaction Mode.
  - **Prerequisite Check**: Initiating skill system validates cooldowns/conditions before request.
- **Sustain Condition**: Maintained while key is held (or based on toggle).
- **End Condition**: Released key (Key Up) OR timeout reached.
  - Must dispatch an `Event_InteractionEnded` (timeout treated same as manual exit).
  - Must notify the *active skill system* to finalize its action.
- **Input Access**:
  - **Exclusive Control**: Standard inputs (WASD, Backspace, Ctrl, T) are disabled or consumed by the specific skill logic during this mode.
  - **Priority**: Interaction Mode > Time Rewind. Trumps active rewind; prevents new rewind.

- **Update Loop (Tick)**:
  - **Pause**: `World` updates for standard gameplay entities (Physics, AI, Movement, Damage, Death) must be entirely skipped (not ticked).
  - **Resume**: Physics/Game Logic resumes from exact pre-interaction state.
  - **Render**: Continue to render the last frame of the game world (background).
  - **Allowlist**: Must allow specific systems (e.g., the `ActiveSkillSystem`, `CameraSystem`, `DisplaySys`) to continue updating.
    - **Dynamic**: The specific skill system requesting the mode is automatically allowed.

- **Time Scale**:
  - `dt` (delta time) passed to the allowed systems must be unscaled (Real Time).
  - No `dt` is passed to the background game world (as those systems are not ticked).

### Skill System Integration & Reference Implementation
- **Decoupled Design**: The Interaction Mode itself **does not** create or manage indicators, nor determine success/failure of the skill.
  - It delegates visual feedback and logic validation to the specific skill systems via events.
- **Camera**: Locked to Player check; since Movement (WASD) is disabled, Camera remains static.
- **Rendering**: Indicators share global game Z-ordering. Off-screen visibility logic handled by specific skill system.
- **Reference Implementation**:
  - A simple "Debug Indicator" system must be implemented to test the interaction loop.
  - This reference implementation should listen for `Event_InteractionStarted`, draw a simple shape at the mouse/target position, and clean up on `Event_InteractionEnded`.


### Time Component Integration
- **Time Recorder**: Must pause recording during Interaction Mode (no frames recorded).
- **State Snapshot**: The state before entering and after exiting should be treated as adjacent in time history.
- **Rewind Logic**: Deterministic replay (no RNG) inherently supported.

## Non-Functional Requirements *(optional)*

- **Responsiveness**: Entering and exiting the mode should be instantaneous (no loading frames).
- **UI/Visual Clarity**: 
  - The paused game state should visually indicate it is paused (e.g., slight desaturation or overlay) - *Placeholder interface required*.
  - UI (HUD/Inventory) behavior updates deferred to future UI system (placeholders ok).
- **Generic Design**: The architecture must allow different skills (Black Hole, Teleport, etc.) to use different indicators and validation logic without rewriting the interaction core.

## Assumptions *(optional)*

- The current ECS architecture allows for pausing specific systems or the entire world update loop.
- `TimeManager` supports a global time scale or distinct 'Game Time' vs 'Real Time' clocks.
- Input handling can distinguish between 'Game Input' and 'Menu/Interaction Input'.

## Success Criteria *(mandatory)*

- **Usability**: Users can successfully target a specific location within 2 seconds of entering the mode.
- **Precision**: Users can place the skill within 50px of their intended target.
- **System Integrity**: Using the mode does not desync the physics engine or causing `TimeRewind` artifacts.
- **Extensibility**: At least 2 different types of skills (e.g., Point Target, Directional Arrow) can be implemented using this system.
