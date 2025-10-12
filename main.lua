
require("lldebugger").start()

local entities = {}
local systems = {}

function love.load()
    package.path = package.path .. ";./Script/?.lua;./Script/utils/?.lua;"
    local Animation = require('Component.AnimationCMP')
    local Entity = require('Entity')
    local displaySys = require('System.DisplaySys'):new()

    systems['DisplaySys'] = displaySys

    local image = love.graphics.newImage("Resources/characters.png")
    print(image)
    love.graphics.setBackgroundColor(255,255,255)
    local animCmp = Animation:new(image, 0, 0, 736, 32, 32, 32)
    local entity = Entity:new('hello')
    entity:boundComponent(animCmp)
    table.insert(entities, entity)
end

function love.update(deltaTime)
    local thisFrameEntities = {}
    for i = 1, #entities do
        table.insert(thisFrameEntities, entities[i])
    end

    systems['DisplaySys']:preCollect()
    
    for i = 1, #entities do
        if entities[i] ~= nil then
            systems['DisplaySys']:collect(entities[i])
        end
    end

    systems['DisplaySys']:tick(deltaTime)
end

function love.draw()
    systems['DisplaySys']:draw()
end