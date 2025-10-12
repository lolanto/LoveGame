--- divlib.lua
--- Lua 整除判断工具库
local divlib = {}

--- 判断 B 是否能整除 A
--- @param A number 被除数
--- @param B number 除数
--- @return boolean 可以整除返回 true，否则 false
function divlib.isDivisible(A, B)
    if B == 0 then
        return false  -- 避免除零错误
    end
    return A % B == 0
end

--- 获取 A 除以 B 的余数
--- @param A number 被除数
--- @param B number 除数
--- @return number 余数，如果 B 为 0，则返回 nil
function divlib.mod(A, B)
    if B == 0 then
        return nil
    end
    return A % B
end

--- 获取 A 除以 B 的商（整数部分）
--- @param A number 被除数
--- @param B number 除数
--- @return number 商，如果 B 为 0，则返回 nil
function divlib.quotient(A, B)
    if B == 0 then
        return nil
    end
    return math.floor(A / B)
end

--- 获取 A 除以 B 的结果及是否整除
--- @param A number 被除数
--- @param B number 除数
--- @return number 商或 nil, boolean 是否整除
function divlib.divmod(A, B)
    if B == 0 then
        return nil, false
    end
    local remainder = A % B
    local quotient = (A - remainder) / B
    return quotient, remainder == 0
end

return divlib