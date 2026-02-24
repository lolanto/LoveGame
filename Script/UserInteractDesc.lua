
---@class KeyInteractDesc
---@field _isPressed boolean 是否按下
---@field _isReleased boolean 是否松开
---@field _pressingDuration number 按下持续的时间(second)
---@field _isConsumed boolean
local KeyInteractDesc = {}
KeyInteractDesc.__index = KeyInteractDesc

function KeyInteractDesc:new()
    local instance = setmetatable({}, KeyInteractDesc)
    instance._isPressed = false
    instance._isReleased = false
    instance._isConsumed = false
    instance._pressingDuration = 0
    return instance
end

function KeyInteractDesc:setPressed()
    assert(self._isPressed == false, 'why double pressed??')
    self._isPressed = true
    self._pressingDuration = 0
    self._isReleased = false
end

function KeyInteractDesc:setReleased()
    assert(self._isReleased == false and self._isPressed == true, 'why double released? or release before pressed!?')
    self._isPressed = false
    self._isReleased = true
    self._pressingDuration = 0
end

function KeyInteractDesc:preUpdate(deltaTime)
    if self._isPressed then
        self._pressingDuration = self._pressingDuration + deltaTime
    end
end

function KeyInteractDesc:postUpdate()
    self._isConsumed = false
end

function KeyInteractDesc:getIsPressed()
    return self._isPressed, self._pressingDuration
end

function KeyInteractDesc:getIsReleased()
    return self._isReleased
end

function KeyInteractDesc:setConsumed()
    self._isConsumed = true
end

---@class KeyboardInteractDesc : KeyInteractDesc
---@field _isTap boolean 是否完成了一次敲击
local KeyboardInteractDesc = setmetatable({}, KeyInteractDesc)
KeyboardInteractDesc.__index = KeyboardInteractDesc

function KeyboardInteractDesc:new()
    local instance = setmetatable(KeyInteractDesc.new(self), self)
    instance._isTap = false
    return instance
end

function KeyboardInteractDesc:setReleased()
    if self._pressingDuration < 1e-1 then
        self._isTap = true
    end
    KeyInteractDesc.setReleased(self)
end

function KeyboardInteractDesc:preUpdate(deltaTime)
    KeyInteractDesc.preUpdate(self, deltaTime)
end

function KeyboardInteractDesc:postUpdate()
    KeyInteractDesc.postUpdate(self)
    self._isTap = false
end

function KeyboardInteractDesc:getIsTap()
    return self._isTap
end

---@class MouseInteractDesc:KeyInteractDesc
---@field _posX number 发生事件的鼠标位置x
---@field _posY number 发生事件的鼠标位置y
---@field _isSingleClick boolean 是否完成了单击
---@field _isDoubleClick boolean 是否完成了双击
local MouseInteractDesc = setmetatable({}, KeyInteractDesc)
MouseInteractDesc.__index = MouseInteractDesc

function MouseInteractDesc:new()
    local instance = setmetatable(KeyInteractDesc.new(self), self)
    instance._posX = 0
    instance._posY = 0
    instance._isSingleClick = false
    instance._isDoubleClick = false --todo: 暂时不支持双击检查，理论上应该做到引擎回调里
    return instance
end

function MouseInteractDesc:setPressed(x, y)
    KeyInteractDesc.setPressed(self)
    self._posX = x
    self._posY = y
end

function MouseInteractDesc:setReleased(x, y)
    self._posX = x
    self._posY = y
    if self._pressingDuration < 1e-1 then
        self._isSingleClick = true
    end
    KeyInteractDesc.setReleased(self)
end

function MouseInteractDesc:preUpdate(deltaTime)
    KeyInteractDesc.preUpdate(self, deltaTime)
end

function MouseInteractDesc:postUpdate()
    KeyInteractDesc.postUpdate(self)
    self._isSingleClick = false
end

function MouseInteractDesc:getIsSingleClick()
    return self._isSingleClick
end


---@class InteractConsumeInfo
---@field _checkFunc fun(obj:KeyboardInteractDesc|MouseInteractDesc|nil):boolean
local InteractConsumeInfo = {}
InteractConsumeInfo.__index = InteractConsumeInfo

---cst, 用来构建指定交互组合在当前交互状态下是否满足
---@param checkFunction fun(obj:KeyboardInteractDesc|MouseInteractDesc|nil):boolean 用来检查交互状态的函数
function InteractConsumeInfo:new(checkFunction)
    local instance = setmetatable({}, self)
    instance._checkFunc = checkFunction or function() return false end
    return instance
end

---检查当前用户的交互信息是否满足要求
---@param obj KeyboardInteractDesc|MouseInteractDesc|nil
---@return boolean 假如交互信息中存在满足检查函数的情况，返回True，否则返回False
function InteractConsumeInfo:doCheck(obj)
    if obj == nil then return false end
    if obj._isConsumed then return false end -- 指令已经被处理过了，就不再响应了
    return self._checkFunc(obj)
end

return {
    KeyInteractDesc = KeyInteractDesc,
    KeyboardInteractDesc = KeyboardInteractDesc,
    MouseInteractDesc = MouseInteractDesc,
    InteractConsumeInfo = InteractConsumeInfo,
}
