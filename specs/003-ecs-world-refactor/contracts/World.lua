---@class World
---@field entities table<number, Entity>
---@field systems table<number, System>
---@field views table<string, ComponentsView>
local World = {}

---@param entity Entity
function World:addEntity(entity) end

---@param entity Entity
function World:removeEntity(entity) end

---@param system System
function World:registerSystem(system) end

---@param dt number
function World:update(dt) end

return {
    World = World
}
