# DrawableCMP

The base class for all components that can be rendered to the screen.

## associate systems
* [DisplaySys](../systems/display-system.md)

## member properties
### 1. _maxBounding (protected)
Defines the maximum bounding box of the visual element (for culling purposes). Not strictly mandated but recommended for subclasses.
### 2. _layer (protected)
Rendering layer index. Higher values are drawn on top of lower values. Default is 0.

## member functions
### 1. new() (public)
Constructor. Initializes layer to 0.

### 2. draw(transform) (public)
**Abstract method.** Must be overridden by subclasses.
Executed by `DisplaySys`. Receives the World Transform of the entity to guide rendering.

### 3. getMaxBounding() (public)
Returns the stored bounding box.

### 4. getLayer() (public)
Returns the current rendering layer.

### 5. setLayer(layer) (public)
Sets the rendering layer.

## static properties
### 1. ComponentTypeName (public)
String identifier: "DrawableCMP".
### 2. ComponentTypeID (public)
Numeric ID registered with `BaseComponent`.

## static functions
(None)
