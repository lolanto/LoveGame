# MainCharacterInteractSys

This system handles the specific interaction logic for the main character, translating input commands into movement velocity.

## associate components
* [MainCharacterControllerCMP](../components/main-character-controller-component.md)
* [MovementCMP](../components/movement-component.md)

## member properties
### 1. _userInteractController (private)
Reference to the `UserInteractController` to process inputs (though currently inputs seem to be processed via `MainCharacterControllerCMP` state derived elsewhere or passed in). The system stores this reference via `setupUserInteractController`.

### 2. WalkSpeed (public/static-like)
Defines the walking speed of the character (2.0 m/s).

## member functions
### 1. new() (public)
Constructor. Registers requirements for `MainCharacterControllerCMP` and `MovementCMP`.

### 2. collect(entity) (public)
Overrides `BaseSystem:collect` to ensure only one main character is controlled.

### 3. setupCharacterEntity(entity) (public)
Helper to manually setup the character entity.

### 4. setupUserInteractController(userInteractController) (public)
Dependency injection for the input controller.

### 5. tick(deltaTime) (public)
Processes gameplay logic for the character.
- Reads `ControlCommands` from `MainCharacterControllerCMP`.
- Calculates a movement direction vector based on active commands (Forward/Backward/Left/Right).
- Normalizes the vector.
- Sets the velocity on the `MovementCMP` based on `WalkSpeed`.

## static properties
### 1. SystemTypeName (public)
String identifier: "MainCharacterInteractSys".

## static functions
(None)
