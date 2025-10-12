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

---尝试检查请求的组合是否存在
---@param consumeInfos {string:InteractConsumeInfo}
---@return boolean 假如都满足组合要求，返回true，否则返回false
function UserInteractController:tryToConsumeInteractInfo(consumeInfos)
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

---update
function UserInteractController:preUpdate(deltaTime)
    for key, descObj in pairs(self._interactStates) do
        descObj:preUpdate(deltaTime)
    end
end

function UserInteractController:postUpdate()
    for key, descObj in pairs(self._interactStates) do
        descObj:postUpdate()
    end
end

-- Callbacks

function UserInteractController:onKeyPressed(key)
end
