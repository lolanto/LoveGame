local MUtils = require('MUtils')
local EventInterfaces = require('EventInterfaces')

local LOG_MODULE = "MessageCenter"

--[[
    事件回调句柄 - 封装回调函数、上下文及调试信息
]]
local EventCallbackObject = {}
EventCallbackObject.__index = EventCallbackObject

---@param callback function
---@param subscriber EventInterfaces.ISubscriber 用于获取ID和Name的订阅者对象
---@param subscriberContext any 回调函数执行时的第一个参数（上下文）
---@param debugInfo string|nil
function EventCallbackObject:new(callback, subscriber, subscriberContext, debugInfo)
    local instance = setmetatable({}, EventCallbackObject)
    instance.func = callback
    instance.subscriberContext = subscriberContext
    
    -- [GC Optimization] 只持有 ID 和 Name，不直接引用 Subscriber 对象
    instance.subscriberID = subscriber:getSubscriberID()
    instance.subscriberName = subscriber:getSubscriberName()
    
    instance.debugInfo = debugInfo or ""
    return instance
end

--[[
    事件对象类 - 封装事件名称、广播者、订阅者
]]
local EventObject = {}
EventObject.__index = EventObject

---EventObject 构造函数
---@param name string 事件名称
function EventObject:new(name)
    local instance = setmetatable({}, EventObject)
    instance.name = name
    --[Refactor] 不再绑定 Broadcaster，允许任意 Valid Broadcaster 触发
    
    instance.listeners = {} -- Map: { [handlerID] = EventCallbackObject }
    instance.nextHandlerID = 1
    return instance
end

---订阅该事件
---@param subscriber table ISubscriber 订阅者对象
---@param callback function 回调函数
---@param subscriberContext any 上下文
---@param debugInfo string|nil 调试信息
---@return number handlerID 返回句柄ID，用于取消订阅
function EventObject:subscribe(subscriber, callback, subscriberContext, debugInfo)
    local handler = EventCallbackObject:new(callback, subscriber, subscriberContext, debugInfo)
    
    local id = self.nextHandlerID
    self.nextHandlerID = self.nextHandlerID + 1
    
    self.listeners[id] = handler
    return id
end

---取消订阅
---@param handlerID number 订阅时返回的ID
function EventObject:unsubscribe(handlerID)
    if self.listeners[handlerID] then
        self.listeners[handlerID] = nil
    end
end

---触发事件（内部调用）
---@param broadcaster table IBroadcaster
---@param broadcasterContext any
function EventObject:trigger(broadcaster, broadcasterContext)
    -- 创建快照以支持在回调中修改订阅列表 (Adding/Removing listeners)
    -- 注意：pairs遍历顺序未定义
    local safeList = {}
    for _, handler in pairs(self.listeners) do
        table.insert(safeList, handler)
    end
    local broadcasterName = broadcaster:getBroadcasterName()

    for _, handler in ipairs(safeList) do
        local status, err
        -- 传递 subscriberContext 作为第一个参数，broadcasterContext 作为第二个参数
        status, err = pcall(handler.func, handler.subscriberContext, broadcasterContext)
        
        if not status then
            -- 使用存储在 Handler 中的 subscriberName 进行日志打印
            MUtils.Log(LOG_MODULE, string.format("Event: '%s' (From: %s) | Subscriber: '%s' | HandlerInfo: '%s' | Error: %s", 
                self.name, broadcasterName, handler.subscriberName, handler.debugInfo, tostring(err)))
        end
    end
end

--[[
    MessageCenter - 事件对象管理器
]]
local MessageCenter = {}
MessageCenter.__index = MessageCenter

MessageCenter.static = {}
MessageCenter.static.instance = nil

function MessageCenter.static.getInstance()
    if MessageCenter.static.instance == nil then
        MessageCenter.static.instance = MessageCenter:new()
    end
    return MessageCenter.static.instance
end

function MessageCenter:new()
    assert(MessageCenter.static.instance == nil, 'MessageCenter can only have one instance!')
    local instance = setmetatable({}, MessageCenter)

    -- 注册日志模块
    MUtils.RegisterModule(LOG_MODULE)

    -- 事件对象映射: { ["EventName"] = EventObject }
    instance.events = {}
    -- 延迟事件队列
    instance.eventQueue = {}
    
    return instance
end

---校验是否为合法的Broadcaster
---@param obj any
---@return boolean
function MessageCenter:_isValidBroadcaster(obj)
    return type(obj) == 'table' and obj.IsBroadcaster == true
end

---校验是否为合法的Subscriber
---@param obj any
---@return boolean
function MessageCenter:_isValidSubscriber(obj)
    return type(obj) == 'table' and obj.IsSubscriber == true
end

---创建/获取并注册一个事件对象
---@param eventName string 事件名
---@return table EventObject
function MessageCenter:registerEvent(eventName)
    if self.events[eventName] then
        MUtils.Warning(LOG_MODULE, "Event '" .. eventName .. "' is already registered. Returning existing event.")
        return self.events[eventName]
    end
    
    local newEvent = EventObject:new(eventName)
    self.events[eventName] = newEvent
    return newEvent
end

---订阅事件 (必须传入 EventObject)
---@param eventObject table EventObject 事件对象
---@param subscriber table ISubscriber 订阅者对象 (用于身份校验)
---@param callback function 回调函数
---@param subscriberContext any 回调函数的执行上下文 (传给回调的第一个参数)
---@param debugInfo string|nil 可选：调试信息
---@return number|nil handlerID 返回句柄ID，如果失败返回nil
function MessageCenter:subscribe(eventObject, subscriber, callback, subscriberContext, debugInfo)
    if type(eventObject) ~= 'table' or getmetatable(eventObject) ~= EventObject then
        MUtils.Error(LOG_MODULE, "Subscribe failed: Invalid parameter, expected EventObject.")
        return nil
    end

    if not self:_isValidSubscriber(subscriber) then
        MUtils.Error(LOG_MODULE, string.format("Subscribe failed: Parameter 'subscriber' must inherit from ISubscriber. Event: %s", eventObject.name))
        return nil
    end

    return eventObject:subscribe(subscriber, callback, subscriberContext, debugInfo)
end

---取消订阅 (必须传入 EventObject)
---@param eventObject table EventObject 事件对象
---@param handlerID number 订阅时返回的句柄ID
function MessageCenter:unsubscribe(eventObject, handlerID)
    if type(eventObject) ~= 'table' or getmetatable(eventObject) ~= EventObject then
        MUtils.Warning(LOG_MODULE, "Unsubscribe failed: Invalid parameter, expected EventObject.")
        return
    end
    eventObject:unsubscribe(handlerID)
end

---立即广播：不进队列，当前调用栈直接执行 (必须传入 EventObject)
---@param broadcaster table IBroadcaster 广播者
---@param eventObject table EventObject 事件对象
---@param broadcasterContext any 传递的数据
function MessageCenter:broadcastImmediate(broadcaster, eventObject, broadcasterContext)
    if not self:_isValidBroadcaster(broadcaster) then
        MUtils.Error(LOG_MODULE, "BroadcastImmediate failed: Invalid parameter, expected IBroadcaster.")
        return
    end

    if type(eventObject) ~= 'table' or getmetatable(eventObject) ~= EventObject then
        MUtils.Error(LOG_MODULE, "BroadcastImmediate failed: Invalid parameter, expected EventObject.")
        return 
    end
    eventObject:trigger(broadcaster, broadcasterContext)
end

---普通广播：进入队列，在下一帧（或Tick开始时）统一执行 (必须传入 EventObject)
---@param broadcaster table IBroadcaster 广播者
---@param eventObject table EventObject 事件对象
---@param broadcasterContext any 传递的数据
function MessageCenter:broadcast(broadcaster, eventObject, broadcasterContext)
    if not self:_isValidBroadcaster(broadcaster) then
        MUtils.Error(LOG_MODULE, "Broadcast failed: Invalid parameter, expected IBroadcaster.")
        return
    end

    if type(eventObject) ~= 'table' or getmetatable(eventObject) ~= EventObject then
        MUtils.Error(LOG_MODULE, "Broadcast failed: Invalid parameter, expected EventObject.")
        return
    end
    table.insert(self.eventQueue, { event = eventObject, broadcaster = broadcaster, broadcasterContext = broadcasterContext })
end

---处理队列中的事件 (建议在 love.update 开头调用)
function MessageCenter:dispatch()
    if #self.eventQueue == 0 then return end

    -- 锁定当前队列
    local currentQueue = self.eventQueue
    self.eventQueue = {}

    for _, item in ipairs(currentQueue) do
        if item.event then
            item.event:trigger(item.broadcaster, item.broadcasterContext)
        end
    end
end

return {
    MessageCenter = MessageCenter,
    EventObject = EventObject,
    EventCallbackObject = EventCallbackObject
}
