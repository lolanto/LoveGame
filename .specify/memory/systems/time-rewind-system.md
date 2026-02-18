# TimeRewindSys

This system implements the core "Time Rewind" mechanic. It records component states over time and replays them when triggered.

## associate components
This system iterates over all components that implement the rewind interface (e.g. `getRewindState_const`) on entities marked for rewind.

## member properties
### 1. _isRewinding (private)
Boolean flag for current mode (Recording vs Rewinding).

### 2. _history (private)
A stack of snapshot frames. Each frame contains data for all rewindable entities.

### 3. _maxHistoryDuration (private)
Max duration to record (default 10.0s).

### 4. _rewindSpeedMultiplier (private)
Speed at which time flows backwards (default 4.0x).

## member functions
### 1. new() (public)
Constructor. Subscribes to `Event_LevelUnloaded` to cleanup.

### 2. collect(entity) (public)
Overrides collect. Only collects entities where `entity:getNeedRewind_const()` is true.

### 3. tick(deltaTime) (public)
- If rewinding: Calls `rewind(deltaTime)`.
- If recording: Calls `record(deltaTime)`.

### 4. record(deltaTime) (private)
Captures state.
- Iterates collected entities.
- For each component, checks `getRewindState_const`.
- Stores deep copy of state in history stack.
- Trims history older than `_maxHistoryDuration`.

### 5. rewind(deltaTime) (private)
Replays state.
- Decrements `_currentRecordTime`.
- Finds two snapshots surrounding current time.
- Interpolates between them (`lerpRewindState` or `restoreRewindState`).
- Restores state to components.

### 6. enableRewind(enable) (public)
Toggles mode. Handling logic for time scale (forces 1.0 time scale during rewind).

### 7. processUserInput(controller) (public)
Checks for "Backspace" key to toggle rewind.

## static properties
### 1. SystemTypeName (public)
String identifier: "TimeRewindSys".

## static functions
(None)
