# AnimationCMP

A drawable component that renders an animated sprite from a spritesheet.

## associate systems
* [DisplaySys](../systems/display-system.md)

## member properties
### 1. _sheet (protected)
The Source Image (Spritesheet).
### 2. _frames (protected)
A list of `love.Quad` objects acting as the frames of the animation.
### 3. _curFrameIdx (protected)
Index of the current frame (1-based).
### 4. _timeForNextFrame (protected)
Countdown timer for the next frame switch.
### 5. _frameRate, _invFrameRate (protected)
Playback speed settings (default 12 FPS).

## member functions
### 1. new(image, ...) (public)
Constructor. Slices the provided image into Quads based on grid parameters (topLeft, bottomRight, frameSize).

### 2. update(deltaTime) (public)
Advances the animation timer.
- Respects `TimeManager:getDeltaTime()` (Time Dilation).
- Loops the animation when reaching the end.

### 3. draw(transform) (public)
Renders the current frame.
- Applies a local offset (-0.5, -0.5) and scale so that one "Frame" visually occupies 1x1 meters in the world.

### 4. getRewindState_const(), restoreFromRewindState(state), lerpRewindState(a,b,t) (public)
**Time Rewind Implementation**: Saves/Restores `_curFrameIdx` and `_timeForNextFrame`. Supports sub-frame interpolation during rewind.

## static properties
### 1. ComponentTypeName (public)
String identifier: "AnimationCMP".
### 2. ComponentTypeID (public)
Numeric ID registered with `BaseComponent`.

## static functions
(None)
