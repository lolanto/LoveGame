# Data Model: ECS World Refactor

## 1. World (Singleton)

Manages the global state of the ECS.

| Property | Type | Description |
| :--- | :--- | :--- |
| `_entities` | `table<Entity>` | List of currently active entities. |
| `_systems` | `table<BaseSystem>` | List of registered systems. |
| `_views` | `table<string, ComponentsView>` | Cache of active Views, keyed by signature. |
| `_pendingAdd` | `table<Entity>` | Queue of entities to add next tick. |
| `_pendingRemove` | `table<Entity>` | Queue of entities to remove next tick. |
| `_refCount` | `number` | (Optional) Global ref count if needed (unlikely). |

| Method | Signature | Description |
| :--- | :--- | :--- |
| `addEntity` | `addEntity(entity: Entity)` | Adds entity to world (recursive). |
| `removeEntity` | `removeEntity(entity: Entity)` | Marks entity for removal (recursive). |
| `registerSystem` | `registerSystem(sys: BaseSystem)` | Registers a system. |
| `getComponentsView` | `get(required: string[], optional: string[])` | Returns a `ComponentsView`. |
| `onEntityComponentChange` | `(entity, componentName, action)` | Called when entity adds/removes component. |
| `update` | `update(dt)` | Main loop: process queues, update systems, perform GC. |
| `_gc` | `_finalizeDestruction()` | Internal: Checks pending destroy queue and refcounts. |

## 2. ComponentsView

Optimized query cache.

| Property | Type | Description |
| :--- | :--- | :--- |
| `required` | `string[]` | List of required component names. |
| `optional` | `string[]` | List of optional component names. |
| `entities` | `Entity[]` | List of entities in this view. |
| `components` | `table<string, Component[]>` | Map of component name -> specific array (SoA). |
| `_refCount` | `number` | How many systems are using this View. |

**Sentinel Rule**: If an entity lacks an optional component, the array stores `ComponentsView.EMPTY`.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `add` | `add(entity: Entity)` | Adds entity if it matches criteria. Populates `components` arrays. |
| `remove` | `remove(entity: Entity)` | Removes entity (shifts arrays to preserve order). |
| `checkMatch` | `checkMatch(entity): boolean` | Returns true if entity has all `required`. |
| `iterate` | `iterate(): iterator` | Returns iterator for SoA. |

## 3. Entity (Updates)

| Property | Type | Description |
| :--- | :--- | :--- |
| `_refCount` | `number` | Reference counter. Default 0. |

| Method | Signature | Description |
| :--- | :--- | :--- |
| `retain` | `retain()` | `_refCount++`. Recursive to children. |
| `release` | `release()` | `_refCount--`. Recursive to children. |
| `isValid` | `isValid(): boolean` | True if not marked for destruction (or refCount > 0). |

## 4. BaseSystem (Updates)

| Property | Type | Description |
| :--- | :--- | :--- |
| `world` | `World` | Reference to the World. |
| `view` | `ComponentsView` | The primary view this system iterates over. |

| Method | Signature | Description |
| :--- | :--- | :--- |
| `addComponentRequirement` | `(req, opt)` | Declares needs. Creates `view`. |
