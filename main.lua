package.path = package.path .. ";../?.lua"
local AnimationCS = {
	Component = require("Components.CAnimation"),
	System = require("Systems.SAnimation")
}
local PositionCS = {
	Component = require("Components.CPosition"),
	System = nil
}

local VelocityC = require("Components.CVelocity")
local UserInputCS = {
	Component = require("Components.CUserInput"),
	System = require("Systems.SUserInput")
}

local MovingS = require("Systems.SMoving")

local Entity = require("Entity.Entity")

SystemHelper = {
	input = {
		up = {
			pressed = false,
			travel = 0
		},
		down = {
			pressed = false,
			travel = 0
		},
		left = {
			pressed = false,
			travel = 0
		},
		right = {
			pressed = false,
			travel = 0
		}
	},
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
	door2:AddComponent(UserInputCS.Component.Create())
	door2:AddComponent(VelocityC.Create())
end

function love.update(dt)
	SystemHelper.deltaTime = dt
	SystemHelper.totalTime = SystemHelper.totalTime + dt
	UserInputCS.System(SystemHelper, { door, door2 })
	MovingS(SystemHelper, { door, door2 })
	AnimationCS.System(SystemHelper, { door, door2 })
end

function love.draw()
	for i,v in ipairs(SystemHelper.drawCall) do
		v()
	end
	SystemHelper.drawCall = {}
end

function love.keypressed(key, scancode, isrepeat)
	table.insert(SystemHelper.drawCall, function()
		love.graphics.print(key, 0, 0)
		end)
	local input = SystemHelper.input
	if (key == "w") then input.up.pressed = true end
	if (key == "s") then input.down.pressed = true end
	if (key == "a") then input.left.pressed = true end
	if (key == "d") then input.right.pressed = true end
end

function love.keyreleased(key)
	local input = SystemHelper.input
	if (key == "w") then input.up.pressed = false end
	if (key == "s") then input.down.pressed = false end
	if (key == "a") then input.left.pressed = false end
	if (key == "d") then input.right.pressed = false end
end

--]]