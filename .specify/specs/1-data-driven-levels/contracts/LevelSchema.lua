---@meta LevelSchema

---@class LevelData
---@field name string
---@field entities EntityData[]

---@class EntityData
---@field name string
---@field tag string|nil
---@field rewind boolean|nil
---@field components ComponentData[]
---@field children EntityData[]|nil

---@class ComponentData
---@field type string Component Class Name (e.g. "TransformCMP")
---@field args any[]|nil Arguments passed to :new()
---@field properties table<string, any>|nil Properties to set after init
