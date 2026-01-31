--- Level类的基类，定义了Level需要实现的接口
--- @class BaseLevel
--- @field _name String 关卡名称
--- @field _levelEntities table 记录在当前关卡中的所有实体
--- @field load function 关卡加载函数，接受entities和systems两个参数
local BaseLevel = {}
BaseLevel.__index = BaseLevel

function BaseLevel:new(name)
    local instance = setmetatable({}, self)
    instance._name = name
    instance._levelEntities = {}
    return instance
end

function BaseLevel:getName()
    return self._name
end

--- 加载关卡内容
---@param systems table 存放系统的表
---@return table 返回关卡组件的列表
function BaseLevel:load(systems)
    --- 抛出异常，说明子类必须实现该方法
    error("Level.load() 方法必须在子类中实现！")
    return {}
end

function BaseLevel:addEntity(entity)
    table.insert(self._levelEntities, entity)
end

function BaseLevel:getEntities()
    return self._levelEntities
end

function BaseLevel:removeEntity(entity)
    for i, e in ipairs(self._levelEntities) do
        if e == entity then
            table.remove(self._levelEntities, i)
            return
        end
    end
end

function BaseLevel:unload(entities, systems)
    --- 将记录在_level_entities中的实体，从实体列表中移除

    -- 1. 构建一个查找表 (Set)，以 entity 为 key，true 为 value
    local entitiesToRemove = {}
    for _, entity in ipairs(self._levelEntities) do
        entitiesToRemove[entity] = true
    end
    
    -- 2. 只需要遍历一次总的 entities 列表
    for i = #entities, 1, -1 do
        local entity = entities[i]
        -- 3. O(1) 的时间复杂度检查是否需要移除
        if entitiesToRemove[entity] then
            table.remove(entities, i)
            entitiesToRemove[entity] = false -- 可选：移除引用，帮助垃圾回收
            entity:onLeaveLevel() -- 可以先触发离开事件
        end
    end

    if require('Config').Config.IS_DEBUG then
        -- 调试模式下，再遍历一遍entitiesToRemove，确保所有实体都被移除
        for entity, toRemove in pairs(entitiesToRemove) do
            assert(toRemove == false, "Entity ", entity:getName_const(), " was not removed from entities list during level unload!")
        end
    end

    self._levelEntities = {} 
end

return BaseLevel