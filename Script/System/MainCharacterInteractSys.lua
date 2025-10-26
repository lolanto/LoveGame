
local MOD_BaseSystem = require('BaseSystem').BaseSystem

--- 控制主角交互的逻辑
---@class MainCharacterInteractSys : BaseSystem
local MainCharacterInteractSys = setmetatable({}, MOD_BaseSystem)
MainCharacterInteractSys.__index = MainCharacterInteractSys
MainCharacterInteractSys.SystemTypeName = "MainCharacterInteractSys"

-- gameplay相关的常量
MainCharacterInteractSys.WalkSpeed = 100.0  -- 主角行走速度，单位m/s

function MainCharacterInteractSys:new()
    local instance = setmetatable(MOD_BaseSystem.new(self, MainCharacterInteractSys.SystemTypeName), self)
    local ComponentRequirementDesc = require('BaseSystem').ComponentRequirementDesc
    instance:addComponentRequirement(require('Component.MainCharacterControllerCMP').MainCharacterControllerCMP.ComponentTypeID, ComponentRequirementDesc:new(true, true))
    instance:addComponentRequirement(require('Component.MovementCMP').MovementCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))

    instance._userInteractController = nil -- UserInteractController 用户交互控制器
    return instance
end

--- 从entity身上收集MainCharacterControllerCMP和MovementCMP组件
--- 理论上这个系统只会收集一个主角的组件，假如之前有其它方法已经设置过这些组件，将跳过收集
--- (覆写BaseSystem的collect方法)
---@param entity Entity 目标Entity，将会从这个entity身上搜集组件
---@return nil
function MainCharacterInteractSys:collect(entity)
    local lenOfMainCharCtrlCmps = #self._collectedComponents['MainCharacterControllerCMP']
    local lenOfMovementCmps = #self._collectedComponents['MovementCMP']
    assert(lenOfMainCharCtrlCmps == lenOfMovementCmps, string.format("The count of MainCharacterControllerCMP %d should be equal to the count of MovementCMP %d", lenOfMainCharCtrlCmps, lenOfMovementCmps))
    -- 当且仅当lenOfMainCharCtrlCmps ~= 1时，尝试从entity搜索组件
    while lenOfMainCharCtrlCmps ~= 1 do
        local ignoreThisEntity = false
        local mainCharCtrlCmp = nil
        local movementCmp = nil
        -- 搜索MainCharacterControllerCMP和MovementCMP
        if ignoreThisEntity == false then
            mainCharCtrlCmp = entity:getComponent('MainCharacterControllerCMP')
            if mainCharCtrlCmp == nil then
                ignoreThisEntity = true
            end
        end
        if ignoreThisEntity == false then
            movementCmp = entity:getComponent('MovementCMP')
            if movementCmp == nil then
                ignoreThisEntity = true
            end
        end
        if ignoreThisEntity then
            goto continue
        end

        -- 通过检查，收集组件
        table.insert(self._collectedComponents['MainCharacterControllerCMP'], mainCharCtrlCmp)
        table.insert(self._collectedComponents['MovementCMP'], movementCmp)
        -- 更新计数
        lenOfMainCharCtrlCmps = #self._collectedComponents['MainCharacterControllerCMP']
        lenOfMovementCmps = #self._collectedComponents['MovementCMP']
        
        ::continue::
    end
end

--- 设置主角实体
--- 这个方法会调用collect方法从entity身上收集组件
--- 假如明确哪个entity是主角，可以直接调用这个方法以跳过搜索过程
---@param entity Entity 主角实体
---@return nil
function MainCharacterInteractSys:setupCharacterEntity(entity)
    assert(entity ~= nil, "The entity to setup should not be nil!")
    self:collect(entity)
end

function MainCharacterInteractSys:setupUserInteractController(userInteractController)
    assert(userInteractController ~= nil, "The userInteractController to setup should not be nil!")
    self._userInteractController = userInteractController
end

function MainCharacterInteractSys:tick(deltaTime)
    MOD_BaseSystem:tick()
    local lenOfMainCharCtrlCmps = #self._collectedComponents['MainCharacterControllerCMP']
    local lenOfMovementCmps = #self._collectedComponents['MovementCMP']
    assert(lenOfMainCharCtrlCmps == lenOfMovementCmps, string.format("The count of MainCharacterControllerCMP %d should be equal to the count of MovementCMP %d", lenOfMainCharCtrlCmps, lenOfMovementCmps))
    if lenOfMainCharCtrlCmps == 0 then
        return
    end
    assert(lenOfMainCharCtrlCmps == 1, "There should be only one main character controller component!")
    
    -- 将主角交互逻辑放在这里
    -- 主角产生的交互命令在这里转换成移动组件的属性更新
    ---@type MainCharacterControllerCMP
    local mainCharCtrlCmp = self._collectedComponents['MainCharacterControllerCMP'][1]
    ---@type MovementCMP
    local movementCmp = self._collectedComponents['MovementCMP'][1]
    local controlCommands = mainCharCtrlCmp:getControlCommands()
    -- 处理移动命令
    local moveDir = {x = 0.0, y = 0.0}
    if controlCommands[require('Component.MainCharacterControllerCMP').CharacterControlCommand.MoveForward] == true then
        moveDir.y = moveDir.y - 1.0
    end
    if controlCommands[require('Component.MainCharacterControllerCMP').CharacterControlCommand.MoveBackward] == true then
        moveDir.y = moveDir.y + 1.0
    end
    if controlCommands[require('Component.MainCharacterControllerCMP').CharacterControlCommand.MoveLeft] == true then
        moveDir.x = moveDir.x - 1.0
    end
    if controlCommands[require('Component.MainCharacterControllerCMP').CharacterControlCommand.MoveRight] == true then
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


return {
    MainCharacterInteractSys = MainCharacterInteractSys,
}
