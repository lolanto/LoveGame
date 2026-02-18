# LoveGame Index of Components

This document indexes all the ECS Components currently implemented in the LoveGame project.

## Core Components
- [TransformCMP](./components/transform-component.md): Manages Position, Rotation, and Scale.
- [MovementCMP](./components/movement-component.md): Stores velocity data for movement systems.
- [CameraCMP](./components/camera-component.md): Defines camera viewport and projection settings.

## Physics Components
- [PhysicCMP](./components/physic-component.md): Binds the entity to the Box2D physics simulation.
- [TriggerCMP](./components/trigger-component.md): Provides callbacks for physics collision events.

## Visual Components
- [DrawableCMP](./components/drawable-component.md): Base class for renderable components.
- [AnimationCMP](./components/animation-component.md): Renders animated sprites.
- [DebugColorBlockCMP](./components/debug-color-block-component.md): Renders a solid color rectangle (for debug).
- [DebugColorCircleCMP](./components/debug-color-circle-component.md): Renders a solid color circle (for debug).
- [DebugTileTextureCMP](./components/debug-tile-texture-component.md): Renders an infinite grid background.

## Gameplay Logic Components
- [MainCharacterControllerCMP](./components/main-character-controller-component.md): Buffers user input for the player character.
- [PatrolCMP](./components/patrol-component.md): Configuration for AI patrol behavior.
- [GravitationalFieldCMP](./components/gravitational-field-component.md): Defines continuous attraction force parameters.
- [LifeTimeCMP](./components/lifetime-component.md): Manages entity existence duration.

## Templates
- [template component](./components/template-component.md)