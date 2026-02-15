# Research: ECS World Refactor

## 1. ComponentsView Implementation Strategy

### Problem
We need to store matching components for entities in a way that supports efficient iteration, optional components, and valid Lua array semantics (no `nil` holes).

### Options
1.  **List of Entities**: Store list of `Entity` objects. System calls `entity:getComponent(T)`.
    -   *Pros*: Simple maintenance.
    -   *Cons*: Double lookup (View -> Entity -> Component). Bad cache locality.
2.  **SoA with Sentinel**: Parallel arrays for each Component type. Missing optional components use a constant `NULL` table.
    -   *Pros*: Single lookup (iterate `i`). Good for LuaJIT (dense arrays).
    -   *Cons*: Complex add/remove logic (keeping parallel arrays in sync).

### Decision
**SoA with Shared Global Sentinel (`ComponentsView.EMPTY`)**.
-   **Structure**: `view.components = { [TransformCMP] = {c1, c2, ...}, [VelocityCMP] = {c1, EMPTY, ...} }`
-   **Iteration**: `for i = 1, #view.entities do local t, v = view.components.TransformCMP[i], view.components.VelocityCMP[i] end`
-   **Sentinel**: A globally unique empty table `ComponentsView.EMPTY` (wrapped in `ReadOnly` during Debug).

## 2. Maintaining View Integrity (Dirty State)

### Problem
When an entity adds/removes a component, it may enter/exit Views.

### Options
1.  **Immediate Update**: `entity:addComponent` calls `World:onEntityChanged(entity)`. World immediately scans all Views and updates them.
    -   *Pros*: Views always correct.
    -   *Cons*: Performance spike if adding many components at once.
2.  **Deferred Update**: `entity:addComponent` marks entity `dirty`. `World:update` re-evaluates dirty entities.
    -   *Pros*: Batch processing.
    -   *Cons*: Views Stale until next tick (might be okay if systems run after Update).

### Decision
**Deferred Update (Dirty State)**.
-   **Why**: To ensure iteration stability during System updates. If a System triggers a structural change, we generally want the View to remain consistent for the duration of the tick (or at least until a safety point).
-   **Mechanism**:
    1.  Entity: Modification marks `entity.isArchDirty = true` and adds to `World.dirtyEntities` set.
    2.  World: Before `World:tick()` (or `World:clean()`), iterates `dirtyEntities`.
    3.  For each dirty entity: Calculate new Archetype -> Add/Remove from relevant Views.
    4.  Clear `dirtyEntities`.
-   **Implication**: Systems must handle potentially "stale" views if accessing them mid-frame (or we assume structural changes are rare mid-frame). For "addEntity", the entity won't appear in Views until the next frame (or next clean point), which is standard ECS behavior.

## 3. Order Preservation and Removal

### Problem
Hierarchy updates rely on parent being processed before child. `ComponentsView` order often reflects creation order (parents usually created before children). "Swap-and-pop" (O(1)) destroys this order.

### Options
1.  **Swap-and-Pop**: O(1). Reorders random elements.
    -   *Verdict*: **Rejected**. Breaks hierarchy logic.
2.  **`table.remove`**: O(N). Shifts all subsequent elements.
    -   *Verdict*: **Acceptable**. In LuaJIT, `table.remove` is essentially a `memmove`. For < 10k entities, this is fast enough, especially since removal is rarer than iteration.
3.  **Linked List**: O(1) removal, O(N) iteration.
    -   *Verdict*: **Rejected**. Slow iteration.

### Decision
**`table.remove` (Shift)**.
-   We value iteration speed (every frame) over removal speed (occasional).
-   If performance becomes an issue, we can implement a "Lazy Removal" (swap with `NULL` or mark `dead`) and compact later.

## 4. Time Rewind Integration

### Problem
`TimeRewindSys` needs to keep entities alive even if they are removed from gameplay.

### Strategy
-   **Ref Count**: `Entity._refCount`.
-   **Flow**:
    1.  `World:addEntity`: RefCount = 1 (World holds it).
    2.  `TimeRewindSys:record`: RefCount++.
    3.  `World:removeEntity`: Logic "remove" (removed from `activeEntities`, added to `pendingDestroy`). If RefCount > 1 (held by TimeRewind), do NOT destroy yet.
    4.  `TimeRewindSys:discard`: RefCount--.
    5.  `World/GC`: If `pendingDestroy` entity has RefCount == 0 -> Destroy.
-   **Risk**: `TimeRewindSys` iterating "dead" entities.
    -   **Mitigation**: The Snapshot stores *Data*, not just Entity references. But the Entity reference is needed to *restore* the state?
    -   *Correction*: In ECS, snapshots usually store Component Data. If `TimeRewindSys` restores state by writing data back to components, the Entity *must* exist. Yes.
## 6. ComponentsView: Entity Index Optimization

### Problem
To remove an Entity from a `ComponentsView` (O(1) needed for real-time), we need to know its index `i` in the SoA arrays instantly. Scanning `view.entities` for the entity ID is O(V) (where V is view size), which is too slow (O(N*M) if removing from M views).

### Decision
**Sparse Set / Reverse Index Map**.
-   **Mechanism**:
    -   `ComponentsView` maintains a `entity_to_index` map: `table<EntityID, number>`.
    -   **Add**: `index = #entities + 1; entity_to_index[entity.id] = index`.
    -   **Remove**:
        1.  Get `index` from map.
        2.  Retrieve `last_entity` at `#entities`.
        3.  **Components**: `array[index] = array[last]`. (Swap-and-Pop logic applied to arrays? **Wait**, research decision 3 said `table.remove` to preserve order. We must revisit this conflit).
        -   *Correction*: If we use `table.remove` (shift), all indices > `index` shift down by 1. This invalidates `entity_to_index` for ALL subsequent entities. O(V) cost to update `entity_to_index`.
        -   *Re-evaluation*: Is O(V) acceptable? Yes, because deletions are rare vs iterations.
    -   **Update Map Strategy**:
        -   When removing at `i`:
        -   `table.remove(entities, i)`
        -   `entity_to_index[entity.id] = nil`
        -   **Update Loop**: Iterate `j` from `i` to `#entities`: `entity_to_index[entities[j].id] = j`.
-   **Conclusion**: We will maintain `entity_to_index` to find *where* to start removal quickly, then pay the O(V) shift cost to maintain Hierarchy Order as previously decided.
## 5. View Key Generation

### Strategy
-   Views are keyed by a canonical string signature derived from `System._requiredComponentInfos`.
-   **Context**: Different Systems might require the same set of components but add them in different orders. To maximize View sharing, the signature must be order-independent.
-   **ReadOnly Inclusion**: The signature must distinguish between ReadOnly and Mutable requirements (e.g., `Transform:R` vs `Transform:RW`), as this might affect internal optimization or safety checks, even if the underlying SoA is the same.
-   **Generation Algorithm**:
    1.  Extract all component names from `_requiredComponentInfos`.
    2.  Sort names alphabetically to ensure determinism.
    3.  Iterate sorted names:
        -   Append `Name` to string.
        -   Append flags: `|M` (MustHave/Required) or `|O` (Optional).
        -   Append flags: `|R` (ReadOnly) or `|W` (ReadWrite).
    4.  Join with separator.
-   **Example**: 
    -   System A: Requires `Velocity` (RW), `Transform` (R).
    -   System B: Requires `Transform` (R), `Velocity` (RW).
    -   Both generate: `Transform|M|R;Velocity|M|W;` -> **Same View**.
