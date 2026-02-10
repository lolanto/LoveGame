# LoveGame Index of Systems

This document indexes all the ECS Systems currently implemented in the LoveGame project.

## Core Systems
- [CameraSetupSys](./systems/camera-setup-system.md): Manages camera projection and view matrices.
- [DisplaySys](./systems/display-system.md): Handles rendering of sprites and animations.
- [EntityMovementSys](./systems/entity-movement-system.md): Updates entity positions based on velocity.
- [TransformUpdateSys](./systems/transform-update-system.md): Manages scene graph and World Transform calculations.

## Physics
- [PhysicSys](./systems/physic-system.md): Wraps Box2D simulation and synchronizes with Transforms.
- [PhysicVisualizeSys](./systems/physic-visualize-system.md): Debug system for drawing physics shapes.

## Gameplay Logic
- [MainCharacterInteractSys](./systems/main-character-interact-system.md): Handles Player input and conversion to movement.
- [PatrolSys](./systems/patrol-system.md): AI logic for moving entities along paths or around targets.
- [TriggerSys](./systems/trigger-system.md): Responds to physics collisions to trigger game logic.
- [BlackHoleSys](./systems/black-hole-system.md): Manages Black Hole skills and gravity physics.

## Time Mechanics
- [TimeDilationSys](./systems/time-dilation-system.md): Handles "Slow Motion" effects.
- [TimeRewindSys](./systems/time-rewind-system.md): Handles recording and replaying entity states.

## Templates
- [template system](./systems/template-system.md)