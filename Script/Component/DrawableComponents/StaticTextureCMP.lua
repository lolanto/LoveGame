--[[
    StaticTextureCMP.lua
    描述：用于作为背景的静态纹理组件，会把给定图片以平铺（tilling）方式绘制直到覆盖整个屏幕。
    用法：
        local cmp = StaticTextureCMP:new(imageOrPath, options)
        options = {
            tileScale = 1.0, -- 每个tile的缩放（像素级别），默认1
            offsetX = 0, -- 平铺偏移（像素）
            offsetY = 0,
            layer = -100, -- 绘制层级，默认为很靠后的背景层
        }
    注意：此组件的 draw(transform) 中忽略传入 transform 的平移部分（背景通常固定于屏幕），
    但会尊重缩放以便在摄像机缩放时背景按比例显示。若需要背景跟随世界坐标，请关闭相关约束。
]]

local MOD_BaseComponent = require('BaseComponent').BaseComponent
local MOD_DrawableCMP = require('Component.DrawableCMP').DrawableCMP

---@class StaticTextureCMP : DrawableCMP
---@field _tileScale number
---@field _offsetX number
---@field _offsetY number
---@field _layer number
---@field _image any
---@field _imagePath string|nil
---@field _quad any
local StaticTextureCMP = setmetatable({}, MOD_DrawableCMP)
StaticTextureCMP.__index = StaticTextureCMP
StaticTextureCMP.ComponentTypeName = "StaticTextureCMP"
StaticTextureCMP.ComponentTypeID = MOD_BaseComponent.RegisterType(StaticTextureCMP.ComponentTypeName)

--- 构造函数
--- @param imageOrPath any love Image 对象或图片文件路径（字符串）
--- @param options table 可选项 { tileScale=number, offsetX=number, offsetY=number, layer=number }
function StaticTextureCMP:new(imageOrPath, options)
    local instance = setmetatable(MOD_DrawableCMP.new(self, StaticTextureCMP.ComponentTypeName), self)
    options = options or {}
    instance._tileScale = options.tileScale or 1.0
    instance._offsetX = options.offsetX or 0
    instance._offsetY = options.offsetY or 0
    instance._layer = options.layer or -100
    instance._image = nil
    instance._imagePath = nil
    instance._quad = nil

    -- 支持直接传入 love Image 或文件路径
    if type(imageOrPath) == 'string' then
        instance._imagePath = imageOrPath
        -- 延迟加载到 love.graphics.newImage 以便在 love.load 后调用
    else
        instance._image = imageOrPath
    end

    return instance
end

--- 延迟加载资源，在 draw 时若 image 为空则尝试加载
local function ensureImageLoaded(self)
    if not self._image and self._imagePath then
        -- pcall to avoid hard crash if file not found
        local ok, img = pcall(love.graphics.newImage, self._imagePath)
        if ok and img then
            self._image = img
        else
            print(string.format("StaticTextureCMP: failed to load image '%s'", tostring(self._imagePath)))
            self._image = nil
        end
    end
end

--- 返回组件的最大包围（用于剔除等），对背景返回屏幕大小
function StaticTextureCMP:getMaxBounding()
    local w = love.graphics.getPixelWidth()
    local h = love.graphics.getPixelHeight()
    return { x = 0, y = 0, w = w, h = h }
end

--- 绘制方法：在屏幕上以平铺方式绘制图片
--- @param transform any 传入的世界变换（会读取缩放信息）
function StaticTextureCMP:draw(transform)
    ensureImageLoaded(self)
    if not self._image then
        return
    end

    -- 计算在本地空间需要绘制的 tile 网格（以实体局部原点为中心）
    local screenW = love.graphics.getPixelWidth()
    local screenH = love.graphics.getPixelHeight()

    local imgW = self._image:getWidth()
    local imgH = self._image:getHeight()
    if imgW <= 0 or imgH <= 0 then return end

    local tileW = imgW * self._tileScale
    local tileH = imgH * self._tileScale
    if tileW <= 0 or tileH <= 0 then return end

    -- 估算需要覆盖屏幕的列数与行数（留一点余量）
    local cols = math.ceil(screenW / tileW) + 4
    local rows = math.ceil(screenH / tileH) + 4

    local halfCols = math.floor(cols / 2)
    local halfRows = math.floor(rows / 2)

    -- 保存状态
    local prevColor = {love.graphics.getColor()}
    local prevBlend = love.graphics.getBlendMode()
    love.graphics.setBlendMode('alpha')

    -- 在本地坐标计算每个 tile 的位置，然后用传入的 transform 映射到世界坐标并绘制
    for j = -halfRows, halfRows do
        for i = -halfCols, halfCols do
            local localX = i * tileW + self._offsetX
            local localY = j * tileH + self._offsetY
            local worldX, worldY = localX, localY
            if transform and type(transform.transformPoint) == 'function' then
                worldX, worldY = transform:transformPoint(localX, localY)
            end
            love.graphics.draw(self._image, worldX, worldY, 0, self._tileScale, self._tileScale)
        end
    end

    -- 恢复状态
    love.graphics.setBlendMode(prevBlend)
    love.graphics.setColor(prevColor)
end

return {
    StaticTextureCMP = StaticTextureCMP,
}
