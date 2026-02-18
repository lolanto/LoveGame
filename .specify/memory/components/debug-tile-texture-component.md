# DebugTileTextureCMP

A special drawable component for rendering an infinite tiling background grid useful for level debugging.

## associate systems
* [DisplaySys](../systems/display-system.md)

## member properties
### 1. _image (protected)
The tile texture (default `debug_background_tile.png`).
### 2. _quad (protected)
The quad used for tiling.

## member functions
### 1. new() (public)
Constructor. Sets layer to -1000 (background).

### 2. draw(transform) (public)
Renders the background.
- Calculates how many tiles fit on screen based on Camera ZOOM (Pixels Per Meter).
- Offsets the drawing based on Camera Position to create an infinite scroll effect.
- Assumes 1 Tile = 1 Meter.

## static properties
### 1. ComponentTypeName (public)
String identifier: "DebugTileTextureCMP".
### 2. ComponentTypeID (public)
Numeric ID registered with `BaseComponent`.

## static functions
(None)
