# Analysis Report: 1-data-driven-levels

## 1. Issue Identification
**Violation**: In the implementation plan and subsequent code execution order, component methods (specifically `get/set` accessors in `TransformCMP`) are invoked before the component is formally bound to its entity.

**Evidence**:
*   `TransformCMP.lua` Line 305: `assert(entity ~= nil, "TransformCMP has no owner entity!")` in `getParentTransform()`.
*   `LevelManager.lua` Implementation (T006/T007):
    ```lua
    local component = self:_instantiateComponent(...)
    self:_applyComponentProperties(component, ...) -- Calls methods that might rely on entity
    entity:boundComponent(component) -- Binding occurs AFTER
    ```
*   `architecture.md` Section 2.2: "Component always should be bound to an entity before any of its interface being invoke!"

**Impact**:
*   Runtime crash when a setter (e.g., `setWorldPosition`) requires access to the parent entity or sibling components (which require the entity link).
*   Direct violation of the established Architecture constraints.

## 2. Specification Analysis (spec.md)
*   **Current State**: The Spec defines functional requirements but does not strictly specify the *order* of instantiation vs configuration. It implies a "Load -> Configure" flow which is ambiguous regarding the Entity link.
*   **Deficiency**: Missing Technical Constraint regarding the lifecycle of Component Initialization.

## 3. Plan Analysis (plan.md)
*   **Current State**: Phase 2 tasks imply an order but do not enforce the safety constraint. "Instantiate -> Apply Properties -> Build Entity" flow was implicitly designed in a way that caused this bug.
*   **Deficiency**: Did not foresee the dependency of Component Setters on the Entity (specifically `TransformCMP` needing parent transform).

## 4. Tasks Analysis (tasks.md)
*   **T006** (`_applyComponentProperties`) and **T007** (`_buildEntity`) descriptions are too generic. They do not specify the correct calling sequence (Bind first, then Apply).

## 5. Remediation Plan

**Goal**: Adjust the loading pipeline to ensure `component.entity` is valid before any property setters are called.

**Required Changes**:
1.  **LevelManager.lua (Code Fix)**: 
    *   Change `_buildEntity` to:
        1. Instantiate Component.
        2. Bind Component to Entity (`entity:boundComponent(component)`).
        3. Apply Properties (`_applyComponentProperties`).
2.  **Documents**:
    *   Update `spec.md` Technical Constraints to explicitly forbid component method calls (except constructor) before binding.
    *   Update `plan.md` Summary/Technical Context to reflect this constraint.
    *   Update `tasks.md` to clarify the implementation dependency for **T006** and **T007**.

## 6. Conclusion
The current implementation of the Data-Driven Level loader is fundamentally flawed regarding component initialization order. The documentation needs to reflect the strict order: **Create -> Bind -> Configure**.
