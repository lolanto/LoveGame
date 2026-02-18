# MainCharacterControllerCMP

This component acts as the input buffer for the main character. It translates raw user input into semantic game commands.

## associate systems
* [MainCharacterInteractSys](../systems/main-character-interact-system.md)

## member properties
### 1. _controlCommands (protected)
A table (set) storing active commands for the current frame. Keys are command strings (e.g., "MoveForward").

## member functions
### 1. new() (public)
Constructor. Initializes an empty command set.

### 2. update(deltaTime, userInteractController) (public)
Polls the `userInteractController` for specific key bindings (WASD) and maps them to `CharacterControlCommand` flags in `_controlCommands`.

### 3. getControlCommands() (public)
Returns the table of active commands for the current frame.

### 4. doesCommandIsTriggered(command) (public)
Checks if a specific command is active.

### 5. clearControlCommands() (public)
Clears all active commands.

## static properties
### 1. ComponentTypeName (public)
String identifier: "MainCharacterControllerCMP".
### 2. ComponentTypeID (public)
Numeric ID registered with `BaseComponent`.

## static functions
(None)
