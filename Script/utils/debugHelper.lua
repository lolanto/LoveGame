
local debugHelper = {}

---打印 love.Transform 矩阵到控制台
---@param transform love.Transform 待打印的矩阵
function debugHelper.printMatrix(transform)
    if not transform then
        print("Nil Transform")
        return
    end
    local f_mat1_1, f_mat1_2, f_mat1_3, f_mat1_4
            , f_mat2_1, f_mat2_2, f_mat2_3, f_mat2_4
            , f_mat3_1, f_mat3_2, f_mat3_3, f_mat3_4
            , f_mat4_1, f_mat4_2, f_mat4_3, f_mat4_4 = transform:getMatrix()
    print("--------------")
    print(string.format("|%.2f %.2f %.2f %.2f|", f_mat1_1, f_mat1_2, f_mat1_3, f_mat1_4))
    print(string.format("|%.2f %.2f %.2f %.2f|", f_mat2_1, f_mat2_2, f_mat2_3, f_mat2_4))
    print(string.format("|%.2f %.2f %.2f %.2f|", f_mat3_1, f_mat3_2, f_mat3_3, f_mat3_4))
    print(string.format("|%.2f %.2f %.2f %.2f|", f_mat4_1, f_mat4_2, f_mat4_3, f_mat4_4))
    print("--------------")
end

return debugHelper
