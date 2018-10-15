package.path = package.path .. ";../?.lua"
local AnimationCS = require("Animation.Animation")
local Entity = require("Entity.Entity")

SystemHelper = {
	deltaTime = 0,
	totalTime = 0,
	drawCall = {}
}

local testEntity = Entity.Create()
---[[
function love.load()
	testEntity:AddComponent(AnimationCS.Component.Create(
		love.graphics.newImage("Asset/dungeon_sheet.png"), 
		64, 112, 16, 14, 4, 1.0 / 24,
		true))
end

function love.update(dt)
	SystemHelper.deltaTime = dt
	SystemHelper.totalTime = SystemHelper.totalTime + dt
	SystemHelper.drawCall = {}
	AnimationCS.System(SystemHelper, { testEntity })
end

function love.draw()
	for i,v in ipairs(SystemHelper.drawCall) do
		v()
	end
end
--]]