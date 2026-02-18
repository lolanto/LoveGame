# Data Model: Level System

## Level Data File (`Resources/Level/*.lua`)

Everything is returned as a Lua table.

```lua
return {
    name = "LevelName",
    entities = {
        -- List of entities
    }
}
```

## Entity Data

```lua
{
    name = "entity_name", -- Unique identifier (debug mostly)
    tag = "debug", -- Optional tag
    -- List of components to attach
    components = {
        -- ComponentData objects
    },
    -- List of child entities (recursive)
    children = {
        -- EntityData objects
    },
    -- Special flags
    rewind = true, -- Calls entity:setNeedRewind(true)
}
```

## Component Data

### Structure

```lua
{
    type = "ComponentTypeName", -- e.g., "TransformCMP"
    
    -- Constructor Arguments (passed to :new())
    -- For PhysicCMP, the world is injected automatically by logic, 
    -- so args should match the 'opts' table.
    args = { ... }, 
    
    -- Properties (Setter Injection)
    -- Keys map to setter methods: "key" -> "setKey"
    -- Values are passed as arguments.
    properties = {
        worldPosition = {0, -10}, -- Calls setWorldPosition(0, -10)
        layer = -1,               -- Calls setLayer(-1)
        callback = "funcName",    -- Special handling: binds to Action Script function
    }
}
```

### Specific Component Schemas

#### `PhysicCMP`
*   **Injection**: `LevelManager` injects `PhysicWorld` as 1st arg.
*   **Args**:
    ```lua
    {
        bodyType = "static" | "dynamic" | "kinematic",
        shape = {
            type = "Rectangle" | "Circle",
            -- Rectangle args:
            width = 1, height = 1, x = 0, y = 0, angle = 0, density = 1,
            -- Circle args:
            radius = 1, x = 0, y = 0, density = 1
        },
        fixture = { friction = 0.5, restitution = 0.3 } -- Applied after properties? Or handled in factory?
        -- Current PhysicCMP:new handles fixture creation in constructor provided opts has shape.
    }
    ```
    *Note: `PhysicCMP` constructor expects `opts` to contain instance of `Shape` class, not a table. The Loader must convert the pure data `shape` table into a `Shape` object.*

#### `TransformCMP`
*   **Args**: None (nil).
*   **Properties**:
    ```lua
    {
        worldPosition = { x, y }
    }
    ```

#### `DebugColorBlockCMP`
*   **Args**: `{ r, g, b, a }, width, height` -> Passed as array `{ {r,g,b,a}, w, h }` for unpacking?
    *   *Correction*: Lua `new` usually takes varargs or specific args. `DebugColorBlockCMP:new(color, w, h)`.
    *   Data `args` should correspond to what the loader passes. `unpack` works if `args` is a standard list.

## Action Script (`Script/Level/*.lua`)

Returns a table of functions.

```lua
return {
    onTriggerEnter = function(selfEntity, otherEntity)
        -- Logic here
    end
}
```
