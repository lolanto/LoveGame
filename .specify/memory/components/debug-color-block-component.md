# DebugColorBlockCMP

A simple drawable component that renders a solid colored rectangle. Useful for debug visualization/placeholders.

## associate systems
* [DisplaySys](../systems/display-system.md)

## member properties
### 1. _color (protected)
RGBA table `{r, g, b, a}`.
### 2. _width, _height (protected)
Dimensions of the block in meters.

## member functions
### 1. new(color, width, height) (public)
Constructor.

### 2. draw(transform) (public)
Renders the rectangle.
- Applies color.
- Calculates World Translation and Scale from the transform.
- Centers the rectangle on the entity position.

## static properties
### 1. ComponentTypeName (public)
String identifier: "DebugColorBlockCMP".
### 2. ComponentTypeID (public)
Numeric ID registered with `BaseComponent`.

## static functions
(None)
