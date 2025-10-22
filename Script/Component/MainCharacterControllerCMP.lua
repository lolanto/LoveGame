
--- MainCharacterControllerCMP.lua
--- 这个组件用来处理主角的控制逻辑，负责将用户的输入转换成主角的位置和行为

local MOD_BaseComponent = require('BaseComponent').BaseComponent


local CharacterControlCommand = {
    MoveForward = "MoveForward",
    MoveBackward = "MoveBackward",
    MoveLeft = "MoveLeft",
    MoveRight = "MoveRight",
    Jump = "Jump",
    Crouch = "Crouch",
    Sprint = "Sprint",
    Interact = "Interact",
}

---@class MainCharacterControllerCMP : BaseComponent
---@field _controlCommands {string:boolean} 当前帧被触发的控制命令
local MainCharacterControllerCMP = setmetatable({}, MOD_BaseComponent)
MainCharacterControllerCMP.__index = MainCharacterControllerCMP
MainCharacterControllerCMP.ComponentTypeName = "MainCharacterControllerCMP"
MainCharacterControllerCMP.ComponentTypeID = MOD_BaseComponent.RegisterType(MainCharacterControllerCMP.ComponentTypeName)

function MainCharacterControllerCMP:new()
    local instance = setmetatable(MOD_BaseComponent.new(self, MainCharacterControllerCMP.ComponentTypeName), self)
    instance._controlCommands = {}
    return instance
end

---用来更新主角的控制逻辑，将用户的按键输入转换成用户角色的控制命令
---@param deltaTime number 帧间隔时间(second)
---@param userInteractController UserInteractController 用户交互控制器
---@note 这个方法不是Gameplay的逻辑，所以就不放到System里了
function MainCharacterControllerCMP:update(deltaTime, userInteractController)
    -- 清理上一帧的控制命令
    self._controlCommands = {}
    local keyPressedCheckFunc = function(keyObj)
        if keyObj == nil then return false end
        local isPressed, pressingDuration = keyObj:getIsPressed()
        return isPressed
    end
    -- 判断是否MoveForward命令被触发
    local moveForwardCommandConsumeInfo = {key_w = require('UserInteractDesc').InteractConsumeInfo:new(keyPressedCheckFunc)}
    if userInteractController:tryToConsumeInteractInfo(moveForwardCommandConsumeInfo) then
        self._controlCommands[CharacterControlCommand.MoveForward] = true
    end
    -- 判断是否MoveBackward命令被触发
    local moveBackwardCommandConsumeInfo = {key_s = require('UserInteractDesc').InteractConsumeInfo:new(keyPressedCheckFunc)}
    if userInteractController:tryToConsumeInteractInfo(moveBackwardCommandConsumeInfo) then
        self._controlCommands[CharacterControlCommand.MoveBackward] = true
    end
    -- 判断是否MoveLeft命令被触发
    local moveLeftCommandConsumeInfo = {key_a = require('UserInteractDesc').InteractConsumeInfo:new(keyPressedCheckFunc)}
    if userInteractController:tryToConsumeInteractInfo(moveLeftCommandConsumeInfo) then
        self._controlCommands[CharacterControlCommand.MoveLeft] = true
    end
    -- 判断是否MoveRight命令被触发
    local moveRightCommandConsumeInfo = {key_d = require('UserInteractDesc').InteractConsumeInfo:new(keyPressedCheckFunc)}
    if userInteractController:tryToConsumeInteractInfo(moveRightCommandConsumeInfo) then
        self._controlCommands[CharacterControlCommand.MoveRight] = true
    end
end

---获取当前帧被触发的控制命令
---@return {string:boolean} 控制命令字典
function MainCharacterControllerCMP:getControlCommands()
    return self._controlCommands
end

---获取指定的命令是否被触发
---@param command string 控制命令
---@return boolean 指定的命令是否被触发
function MainCharacterControllerCMP:doesCommandIsTriggered(command)
    return self._controlCommands[command] == true
end

---清除当前帧的控制命令
function MainCharacterControllerCMP:clearControlCommands()
    self._controlCommands = {}
end


return {
    MainCharacterControllerCMP = MainCharacterControllerCMP,
    CharacterControlCommand = CharacterControlCommand,
}