
local MOD_BaseSystem = require('BaseSystem').BaseSystem
local InteractionManager = require('InteractionManager').InteractionManager
local UserInteractDesc = require('UserInteractDesc')

---@class TestInteractionSys : BaseSystem
local TestInteractionSys = setmetatable({}, MOD_BaseSystem)
TestInteractionSys.__index = TestInteractionSys
TestInteractionSys.SystemTypeName = "TestInteractionSys"

function TestInteractionSys:new(world)
    local instance = setmetatable(MOD_BaseSystem.new(self, TestInteractionSys.SystemTypeName, world), self)
    instance:initView()
    instance._isHolding = false
    instance._userInteractController = require('UserInteractController').UserInteractController:new() -- Should use the one from World/Sys ideally, but Systems usually hook globally or via parameter.
    -- Wait, Systems do typically receive UserInput via processUserInput if World calls it.
    -- World calls processUserInput IF the system implements it AND is in the hardcoded list.
    -- TestInteractionSys is NOT in the World's hardcoded list.
    -- So we must hook into input via `love.keypressed` or check manually?
    -- Love2D allows global polling: `love.keyboard.isDown('k')`.
    -- For test system this is acceptable.
    return instance
end

function TestInteractionSys:tick(deltaTime)
    -- Standard Tick (World driven) - Only check for START
    local im = require('InteractionManager').InteractionManager.static.getInstance()
    
    if love.keyboard.isDown('k') then
        if not im:isActive() then
             im:requestStart(self, 5.0, { reason = "Test" })
        end
    end
end

function TestInteractionSys:tick_interaction(deltaTime)
    -- Interaction Tick (IM driven) - Check for END
    local im = require('InteractionManager').InteractionManager.static.getInstance()
    
    -- If key released (or not down), end it
    if not love.keyboard.isDown('k') then
        im:requestEnd("Manual Release")
    end
end
    
function TestInteractionSys:draw()
    local im = require('InteractionManager').InteractionManager.static.getInstance()
    -- Visual Indicator (US2 Preview)
    if im:isActive() and im._initiatorSystem == self then
        local x, y = love.mouse.getPosition()
        love.graphics.setColor(1, 0, 0, 0.5)
        love.graphics.circle("fill", x, y, 30)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("INTERACTION ACTIVE", 10, 50)
    end
end

return TestInteractionSys
