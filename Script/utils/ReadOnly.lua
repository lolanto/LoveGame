--- 通用只读对象创建工具
--- 提供简单的方式创建任何对象的只读版本

--- 创建只读包装器
--- 使用元表拦截所有写操作，只允许读取操作
---@param obj any 要包装的对象
---@param allowedPattern? string 指定允许的访问模式，格式是正则表达式
---@return any 只读包装器
local function makeReadOnly(obj, allowedPattern)

    --- 在非调试模式下，直接返回原对象以提升性能
    if require('Config').Config.IS_DEBUG == false then
        return obj
    end

    if obj == nil then
        return nil
    end
    if obj.check_is_const and type(obj.check_is_const) == "function" and obj:check_is_const() then
        -- 已经是只读对象，直接返回
        return obj
    end
    allowedPattern = allowedPattern or "^.*_const$"  -- 默认允许以 _const 结尾的方法
    assert(type(allowedPattern) == "string", "Invalid arguments to makeReadOnly")

    local wrapper = {}

    local const_cast = function(t)
        return obj
    end

    local check_is_const = function(t)
        return true
    end

    -- 设置元表
    local mt = {
        __index = function(t, k)
            if type(k) == "string" then
                if k == "const_cast" then
                    return const_cast
                end
                if k == "check_is_const" then
                    return check_is_const
                end
                -- 检查方法是否匹配允许模式
                if k:match(allowedPattern) then
                    local method = obj[k]
                    if type(method) == "function" then
                        return method
                    end
                end
                -- 允许访问只读属性（非函数）
                local value = obj[k]
                if type(value) ~= "function" then
                    return value
                end
            end
            error("Access to '" .. tostring(k) .. "' is not allowed in read-only mode")
        end,

        __newindex = function(t, k, v)
            error("Attempt to modify read-only object: cannot set '" .. tostring(k) .. "'")
        end,

        __tostring = function(t)
            return "ReadOnly<" .. tostring(obj) .. ">"
        end
    }

    return setmetatable(wrapper, mt)
end

--- 为组件创建只读版本的便捷函数
---@param component any 组件对象
---@return any 只读组件
local function makeComponentReadOnly(component)
    return makeReadOnly(component, "^.*_const$")  -- 匹配以 _const 结尾的方法
end

--- 示例：为任意组件创建只读版本
--- local readOnlyHealth = makeReadOnly(healthComponent, "^get")  -- 只允许get开头的方法
--- local readOnlyCustom = makeReadOnly(customObj, "safeMethod")  -- 只允许包含safeMethod的方法

return {
    makeReadOnly = makeReadOnly,
    makeComponentReadOnly = makeComponentReadOnly
}