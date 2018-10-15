package.path = package.path .. ";../?.lua"
local AnimationCS = {
	Component = require("Components.CAnimation"),
	System = require("Systems.SAnimation")
}
local PositionCS = {
	Component = require("Components.CPosition"),
	System = nil
}
local Entity = require("Entity.Entity")

SystemHelper = {
	deltaTime = 0,
	totalTime = 0,
	drawCall = {}
}

local door = Entity.Create()
local door2 = Entity.Create()
---[[
function love.load()
	local refImg = love.graphics.newImage("Asset/dungeon_sheet.png")
	door:AddComponent(AnimationCS.Component.Create(
		refImg, 
		64, 112, 16, 14, 4, 1.0 / 24,
		true))
	door:AddComponent(PositionCS.Component.Create( 100, 100))

	door2:AddComponent(AnimationCS.Component.Create(
		refImg,
		0, 135, 48, 23, 5, 1.0 / 24,
		true))
	door2:AddComponent(PositionCS.Component.Create( 200, 200))
end

function love.update(dt)
	SystemHelper.deltaTime = dt
	SystemHelper.totalTime = SystemHelper.totalTime + dt
	SystemHelper.drawCall = {}
	AnimationCS.System(SystemHelper, { door, door2 })
end

function love.draw()
	for i,v in ipairs(SystemHelper.drawCall) do
		v()
	end
end
--]]