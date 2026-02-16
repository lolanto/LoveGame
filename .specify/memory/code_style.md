# Code Style & Implementation Patterns

## singleton Pattern
For global singleton classes (Managers, World), use the `static` table pattern to hold the instance.

**Pattern:**
```lua
local MyManager = {}
MyManager.__index = MyManager
MyManager.static = {}
MyManager.static.instance = nil

function MyManager.static.getInstance()
    if MyManager.static.instance == nil then
        MyManager.static.instance = MyManager:new()
    end
    return MyManager.static.instance
end

function MyManager:new()
    assert(MyManager.static.instance == nil, "MyManager is a singleton!")
    local instance = setmetatable({}, MyManager)
    instance:init()
    return instance
end
```

## Class Definition
*   **One Class Per File**: Return the class table at the end.
*   **Naming**: PascalCase for class names.
*   **Fields**: Use `_` prefix for private/protected fields.

## Requires
*   Do NOT use `Script.` or `utils.` prefixes.
*   Use local variables for required modules.
