--[[
    事件系统基础接口
]]

---@class IBroadcaster
---@field _broadcasterName string
---@field _broadcasterID number
local IBroadcaster = {}
IBroadcaster.__index = IBroadcaster
IBroadcaster.IsBroadcaster = true

-- 全局静态自增ID计数器
IBroadcaster.static = {}
IBroadcaster.static.nextID = 1

function IBroadcaster:new(name)
    local instance = setmetatable({}, IBroadcaster)
    instance._broadcasterName = name or "UnknownBroadcaster"
    
    -- 分配唯一ID并自增
    instance._broadcasterID = IBroadcaster.static.nextID
    IBroadcaster.static.nextID = IBroadcaster.static.nextID + 1
    
    return instance
end

function IBroadcaster:getBroadcasterName()
    return self._broadcasterName
end

---获取唯一ID
function IBroadcaster:getBroadcasterID()
    return self._broadcasterID
end

---@class ISubscriber
---@field _subscriberName string
---@field _subscriberID number
local ISubscriber = {}
ISubscriber.__index = ISubscriber
ISubscriber.IsSubscriber = true

-- 全局静态自增ID计数器
ISubscriber.static = {}
ISubscriber.static.nextID = 1

---订阅者接口基类构造函数
---@param name string 订阅者名称，用于调试
---@param o any
function ISubscriber:new(name, o)
    o = o or {}
    local instance = setmetatable(o, ISubscriber)
    instance._subscriberName = name or "UnknownSubscriber"
    
    -- 分配唯一ID并自增
    instance._subscriberID = ISubscriber.static.nextID
    ISubscriber.static.nextID = ISubscriber.static.nextID + 1

    return instance
end

function ISubscriber:getSubscriberName()
    return self._subscriberName
end

---获取唯一ID
function ISubscriber:getSubscriberID()
    return self._subscriberID
end


return {
    IBroadcaster = IBroadcaster,
    ISubscriber = ISubscriber
}
