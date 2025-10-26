-- DebugTileTexture.lua
-- 用来绘制可缩放的背景网格纹理，使得图片中的每个32x32像素格子对应世界空间的1米

local MOD_BaseComponent = require('BaseComponent').BaseComponent
local MOD_DrawableCMP = require('Component.DrawableCMP').DrawableCMP

---@class DebugTileTextureCMP : DrawableCMP
local DebugTileTextureCMP = setmetatable({}, MOD_DrawableCMP)
DebugTileTextureCMP.__index = DebugTileTextureCMP
DebugTileTextureCMP.ComponentTypeName = "DebugTileTextureCMP"
DebugTileTextureCMP.ComponentTypeID = MOD_BaseComponent.RegisterType(DebugTileTextureCMP.ComponentTypeName)

function DebugTileTextureCMP:new()
    local instance = setmetatable(MOD_DrawableCMP.new(self), self)
    -- tile image (1024x1024, made of 32x32 tiles)
    instance._image = love.graphics.newImage('Resources/debug_background_tile.png')
    instance._tilePixelSize = 32 -- source tile size in pixels
    instance._layer = -1000
    instance._quad = love.graphics.newQuad(0,0, instance._tilePixelSize, instance._tilePixelSize, instance._image:getDimensions())
    return instance
end

--- 绘制背景填充
---@param transform love.Transform
function DebugTileTextureCMP:draw(transform)
    -- get pixelsPerMeter from RenderEnv global if available, otherwise Units
    local renderEnv = require('RenderEnv').RenderEnv.getGlobalInstance()
    local ppm = renderEnv:getPixelsPerMeter_const()

    -- 每个tile是1米，因此ppm也相当于一个tile的像素大小
    local tileDrawSizePx = ppm

    -- extract world translation/scale from provided transform (matrix values are in pixel-space)
    local f_mat1_1, f_mat1_2, f_mat1_3, f_mat1_4
        , f_mat2_1, f_mat2_2, f_mat2_3, f_mat2_4
        , f_mat3_1, f_mat3_2, f_mat3_3, f_mat3_4
        , f_mat4_1, f_mat4_2, f_mat4_3, f_mat4_4 = transform:getMatrix()
    local translateX = f_mat1_4
    local translateY = f_mat2_4

    
    -- screen size in pixels
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    local startOffsetX = math.floor(translateX - (screenW / 2) / tileDrawSizePx)
    local startOffsetY = math.floor(translateY - (screenH / 2) / tileDrawSizePx)

    local tileX = math.floor(screenW / tileDrawSizePx) + 2
    local tileY = math.floor(screenH / tileDrawSizePx) + 2

    for i = -1, tileX do
        for j = -1, tileY do
            local drawX = startOffsetX + i
            local drawY = startOffsetY + j
            love.graphics.draw(self._image, self._quad, drawX, drawY, 0, 1 / self._tilePixelSize, 1 / self._tilePixelSize)
        end
    end
end

return {
    DebugTileTextureCMP = DebugTileTextureCMP
}
