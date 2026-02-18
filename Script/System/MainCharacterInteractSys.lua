
local MOD_BaseSystem = require('BaseSystem').BaseSystem
local MainCharacterControllerCMP = require('Component.MainCharacterControllerCMP').MainCharacterControllerCMP
local CharacterControlCommand = require('Component.MainCharacterControllerCMP').CharacterControlCommand
local MovementCMP = require('Component.MovementCMP').MovementCMP

--- 控制主角交互的逻辑
---@class MainCharacterInteractSys : BaseSystem
local MainCharacterInteractSys = setmetatable({}, MOD_BaseSystem)
MainCharacterInteractSys.__index = MainCharacterInteractSys
MainCharacterInteractSys.SystemTypeName = "MainCharacterInteractSys"

-- gameplay相关的常量
MainCharacterInteractSys.WalkSpeed = 2.0  -- 主角行走速度，单位m/s

function MainCharacterInteractSys:new(world)
    local instance = setmetatable(MOD_BaseSystem.new(self, MainCharacterInteractSys.SystemTypeName, world), self)
    local ComponentRequirementDesc = require('BaseSystem').ComponentRequirementDesc
    instance:addComponentRequirement(MainCharacterControllerCMP.ComponentTypeID, ComponentRequirementDesc:new(true, true))
    instance:addComponentRequirement(MovementCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))

    instance._userInteractController = nil -- UserInteractController 用户交互控制器
    instance:initView()
    return instance
end

function MainCharacterInteractSys:setupUserInteractController(userInteractController)
    assert(userInteractController ~= nil, "The userInteractController to setup should not be nil!")
    self._userInteractController = userInteractController
end

function MainCharacterInteractSys:tick(deltaTime)
    MOD_BaseSystem.tick(self, deltaTime)
    
    local view = self:getComponentsView()
    -- CHANGE: Use ComponentTypeName instead of ComponentTypeID
    local mainCharCtrls = view._components[MainCharacterControllerCMP.ComponentTypeName]
    local movements = view._components[MovementCMP.ComponentTypeName]
    
    if not mainCharCtrls or not movements then return end
    
    local count = view._count
    -- Iterate all main characters (usually 1)
    for i = 1, count do
        ---@type MainCharacterControllerCMP
        local mainCharCtrlCmp = mainCharCtrls[i]
        ---@type MovementCMP
        local movementCmp = movements[i]
        
        -- Optional: Should system update the component if controller is available?
        -- For now, respecting original logic: only consume commands.
        -- If self._userInteractController is set, we COULD update it here to move logic from main.lua.
        -- But for minimal invasion, we keep only consumption logic.
        
        -- 处理移动命令
        local moveDir = {x = 0.0, y = 0.0}
        if mainCharCtrlCmp:doesCommandIsTriggered_const(CharacterControlCommand.MoveForward) then
            moveDir.y = moveDir.y - 1.0
        end
        if mainCharCtrlCmp:doesCommandIsTriggered_const(CharacterControlCommand.MoveBackward) then
            moveDir.y = moveDir.y + 1.0
        end
        if mainCharCtrlCmp:doesCommandIsTriggered_const(CharacterControlCommand.MoveLeft) then
            moveDir.x = moveDir.x - 1.0
        end
        if mainCharCtrlCmp:doesCommandIsTriggered_const(CharacterControlCommand.MoveRight) then
            moveDir.x = moveDir.x + 1.0
        end
        -- 归一化moveDir
        local len = math.sqrt(moveDir.x * moveDir.x + moveDir.y * moveDir.y)
        if len > 0.0 then
            moveDir.x = moveDir.x / len
            moveDir.y = moveDir.y / len
        end
    
        movementCmp:setVelocity(
            moveDir.x * MainCharacterInteractSys.WalkSpeed, -- velocityX
            moveDir.y * MainCharacterInteractSys.WalkSpeed -- velocityY
        )
    end
end


return {
    MainCharacterInteractSys = MainCharacterInteractSys,
}
