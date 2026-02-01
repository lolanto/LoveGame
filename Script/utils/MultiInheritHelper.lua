local MUtils = require('MUtils')
local LOG_MODULE = "MultiInheritHelper"
MUtils.RegisterModule(LOG_MODULE)
--- @class MultiInheritHelper
local MultiInheritHelper = {}

--- 基于提供的代码实现的 createClass，用于多重继承
--- @vararg table type 父类列表
--- @return table type 新创建的类
function MultiInheritHelper.createClass(...)
    local c = {}        -- 新类
    local parents = {...} -- 父类列表

    --- 尝试检查两个父类中，是否存在同名的字段或方法并报警告
    if require('Config').Config.IS_DEBUG then
        local function getClassName(cls)
            --- TODO: 应该给所有的类一个统一方式，让它们能够顺利打印自己的名字
            if cls.SystemTypeName then return cls.SystemTypeName end
            if cls.ComponentTypeName then return cls.ComponentTypeName end
            if cls.ClassName then return cls.ClassName end
            if cls.IsSubscriber then return "ISubscriber" end
            if cls.IsBroadcaster then return "IBroadcaster" end
            return "UnknownClass"
        end

        for i = 1, #parents do
            for j = i + 1, #parents do
                for k, v in pairs(parents[i]) do
                    if k ~= "__index" and k ~= "new" and k ~= "static" and v ~= nil then
                        if parents[j][k] then
                            local name1 = getClassName(parents[i])
                            local name2 = getClassName(parents[j])
                            MUtils.Warning(LOG_MODULE, string.format("Multiple inheritance conflict: field/method '%s' exists in multiple parent classes: %s and %s", k, name1, name2))
                        end
                    end
                end
            end
        end
    end

    -- 在父类列表中搜索指定的键
    setmetatable(c, {__index = function (t, k)
        for i = 1, #parents do
            local v = parents[i][k]
            if v then return v end
        end
    end})

    -- 为新类准备构造函数
    -- 因为 Lua 查找 table 类型的 __index 时不会触发该 table 自身的 metatable。
    -- 改为函数形式，强制通过 c[k] 触发 metatable 查找。
    c.__index = function(t, k)
        return c[k]
    end

    return c
end

return {
    MultiInheritHelper = MultiInheritHelper
}
