# Phase 0: Research Findings

## 1. Lua Data Sandboxing in Love2D

**Goal**: Load level data files safely without executing arbitrary global code or modifying `_G`.
**Findings**:
*   Love2D uses LuaJIT (Lua 5.1 compatible).
*   `loadfile(path)` compiles a file into a chunk (function).
*   `setfenv(chunk, env)` allows setting a restricted environment for that chunk.
*   **Decision**: Use `loadfile` + `setfenv`. The environment will contain helper functions (like specific enum tables if needed) but block `require`, `os`, `io`, etc.
*   The data files should return a table containing the level definition.

## 2. Component Loading & Dependency Injection

**Goal**: Instantiate components from string names (e.g., "PhysicCMP") and inject dependencies (e.g., Physics World).
**Analysis**:
*   `PhysicCMP:new(world, opts)` requires the `love.physics.World` object.
*   `TransformCMP:new()` takes no args, but is configured via setters (e.g., `setWorldPosition`).
**Decision**:
*   The valid component mappings will be registered (or resolved via `require`).
*   The `LevelManager` logic will accept a `context` (containing `systems`).
*   **Special Factories**: Implement a mapping of `ComponentTypeName -> FactoryFunction`.
    *   Default Factory: `Class:new(args)`
    *   PhysicCMP Factory: `Class:new(systems['PhysicSys']:getWorld(), args)`
*   **Property Injection**: After instantiation, the loader will iterate over a `properties` table in the data definition and call corresponding setters (e.g., `pos` -> `setPos` or map keys to method names).

## 3. Logic/Action Binding

**Goal**: Connect `TriggerCMP` callbacks to functions in `Script/Level/LevelX.lua`.
**Analysis**:
*   Current Code: `getComponent('TriggerCMP'):setCallback(func_leftWallTrigger)`.
*   Data Definition: `{ type = "TriggerCMP", properties = { callback = "nextLevel" } }`.
*   Action Script: Returns a table `{ nextLevel = function(self, other) ... end }`.
**Decision**:
*   The Action Script is loaded via `require` (trusted code).
*   The Loader looks up the string function name in the Action Table.
*   The Loader calls `component:setCallback(actionTable[funcName])`.

## 4. Entity Parent/Child Relations

**Analysis**:
*   `Level1.lua` uses `parent:boundChildEntity(child)`.
*   Data Structure: Entities in the data file list can have a `children` list. The loader will recursively load children and bind them.

## 5. Alternatives Considered

*   **JSON/XML**: Too rigid, requires parsing lib. Lua tables are native and fast.
*   **Global `require` for Data**: Forbidden by spec requirements (clean separation).
*   **Modifying Components**: Changing `PhysicCMP` to retrieve world globally. Rejected (Global state violation).
