# TimeDilationSys

This system manages the "Slow Motion" (Bullet Time) effect, triggered by user input.

## associate components
This system operates on the global time scale and does not explicitly require specific components on entities.

## member properties
### 1. _isDilationActive (private)
Boolean state indicating if slow motion is currently active.

### 2. _timeRewindSys (private)
Reference to `TimeRewindSys` to ensure priority (Rewind overrides Dilation).

## member functions
### 1. new() (public)
Constructor.

### 2. setTimeRewindSys(timeRewindSys) (public)
Sets the dependency for the rewind system.

### 3. processUserInput(controller) (public)
Checks if Control keys are pressed.
- If Rewind is active, forces Dilation off.
- If Ctrl pressed: Sets Time Scale to 0.1.
- If Ctrl released: Resets Time Scale to 1.0.

### 4. tick(deltaTime) (public)
Standard tick (currently empty, logic is in `processUserInput`).

## static properties
### 1. SystemTypeName (public)
String identifier: "TimeDilationSys".

## static functions
(None)
