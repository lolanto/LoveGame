# Research: Black Hole Skill

## 1. Accessing Physics Entities
**Problem**: `BlackHoleSys` needs to apply forces to all *other* entities that have physics bodies, but it only "owns" Black Hole entities (via `GravitationalFieldCMP`).

**Options**:
1.  **Iterate All Entities**: Ask `LevelManager` for all entities, check for `PhysicCMP`.
    *   *Pros*: Decoupled.
    *   *Cons*: Slow (O(N) every frame), duplicate work.
2.  **Dependency Injection**: Inject `PhysicSys` into `BlackHoleSys`. Access `PhysicSys`'s collected components.
    *   *Pros*: Efficient (O(M) where M is physics entities), reuses existing collection.
    *   *Cons*: Coupling between systems.

**Decision**: **Option 2 (Dependency Injection)**.
*   **Rationale**: Performance is critical for physics interactions. `PhysicSys` is the authority on physics bodies. The coupling is acceptable for a heavy interaction feature.
*   **Implementation**: Add `setPhysicSys` to `BlackHoleSys`. Call it from `main.lua` setup.

## 2. Input Handling
**Problem**: How to detect the 'T' key cleanly.

**Options**:
1.  **Direct `love.keyboard`**:
    *   *Pros*: Simple, one line.
    *   *Cons*: Hard to remap, breaks input layering/consumption logic.
2.  **`processUserInput` Interface**:
    *   *Pros*: Standard architecture, supports input consumption (preventing multiple actions from one keypress if needed), centralized.
    *   *Cons*: More boilerplate.

**Decision**: **Option 2**.
*   **Rationale**: Explicit requirements in `spec.md` and architectural consistency.

## 3. Configuration
**Location**: `Config.lua`
**Fields**:
*   `BlackHole.TriggerKey`
*   `BlackHole.Radius`
*   `BlackHole.ForceStrength`
*   `BlackHole.Duration`
*   `BlackHole.SpawnOffset`
