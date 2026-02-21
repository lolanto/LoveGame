--[[
这个模块负责处理用户的输入：
1. 将不同输入函数回调的结果，统一到一个模块中进行管理
2. 管理用户交互到各个层级之间的响应传递
--]]

---@class UserInteractController
---@field _interactStates {string:KeyboardInteractDesc|MouseInteractDesc}
local UserInteractController = {}
UserInteractController.__index = UserInteractController

function UserInteractController:new()
    local instance = setmetatable({}, UserInteractController)
    instance._interactStates = {}
    return instance
end

---尝试检查请求的组合是否存在，通常而言，一个命令可能由一个或者多个用户输入组合而成
---@param consumeInfos {string:InteractConsumeInfo}
---@return boolean 假如都满足组合要求，返回true，否则返回false
function UserInteractController:tryToConsumeInteractInfo(consumeInfos)
    -- If Interaction Mode is active, check if the caller is allowed (TODO: Allowlist logic)
    -- For now, relying on World loop pause to prevent standard systems from calling this.
    -- However, specific systems (like Initiator) WILL call this.
    
    local consumeSucceed = true
    for key, info in pairs(consumeInfos) do
        if not info:doCheck(self._interactStates[key]) then
            consumeSucceed = false
            break
        end
    end
    if consumeSucceed == true then
        for key, _ in pairs(consumeInfos) do
            self._interactStates[key]:setConsumed()
        end
    end
    return consumeSucceed
end

---准备更新下一轮的用户交互信息
function UserInteractController:preUpdate(deltaTime)
    for key, descObj in pairs(self._interactStates) do
        descObj:preUpdate(deltaTime)
    end
end

---清理之前的用户交互状态信息
function UserInteractController:postUpdate()
    for key, descObj in pairs(self._interactStates) do
        descObj:postUpdate()
    end
end

-- Callbacks

function UserInteractController:onKeyPressed(key)
    self._interactStates['key_'..key] = self._interactStates['key_'..key] or require('UserInteractDesc').KeyboardInteractDesc:new()
    self._interactStates['key_'..key]:setPressed()
end

function UserInteractController:onKeyReleased(key)
    self._interactStates['key_'..key] = self._interactStates['key_'..key] or require('UserInteractDesc').KeyboardInteractDesc:new()
    self._interactStates['key_'..key]:setReleased()
end

local LoveMouseBottonConstantToStr = {
    [1] = 'left', -- left
    [2] = 'right', -- right
    [3] = 'middle', -- middle
}

function UserInteractController:onMousePressed(x, y, button)
    local buttonStr = LoveMouseBottonConstantToStr[button]
    self._interactStates['mouse_'..buttonStr] = self._interactStates['mouse_'..buttonStr] or require('UserInteractDesc').MouseInteractDesc:new()
    self._interactStates['mouse_'..buttonStr]:setPressed(x, y)
end

function UserInteractController:onMouseReleased(x, y, button)
    local buttonStr = LoveMouseBottonConstantToStr[button]
    self._interactStates['mouse_'..buttonStr] = self._interactStates['mouse_'..buttonStr] or require('UserInteractDesc').MouseInteractDesc:new()
    self._interactStates['mouse_'..buttonStr]:setReleased(x, y)
end


return {
    UserInteractController = UserInteractController,
}

