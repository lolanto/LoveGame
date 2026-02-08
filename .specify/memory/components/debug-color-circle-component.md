# DebugColorCircleCMP

A simple drawable component that renders a solid colored circle.

## associate systems
* [DisplaySys](../systems/display-system.md)

## member properties
### 1. _color (protected)
RGBA table `{r, g, b, a}`.
### 2. _radius (protected)
Radius in meters.

## member functions
### 1. new(color, radius) (public)
Constructor.

### 2. draw(transform) (public)
Renders the circle.
- Applies color.
- Gets world position and scale from transform.
- Draws filled ellipse.

## static properties
### 1. ComponentTypeName (public)
String identifier: "DebugColorCircleCMP".
### 2. ComponentTypeID (public)
Numeric ID registered with `BaseComponent`.

## static functions
(None)
