AnimationComponent = {
	--[[
	img: sprite sheet of the image
	]]
	Create = function(img, x, y, width, height, totalNum, fr, rep, numX)
		rep = rep or false
		numX = numX or nil
		-- parameter checking!
		-- create component
		local ret = {
			m_img = img,
			m_quad = love.graphics.newQuad(x, y, width, height, img:getDimensions()),
			m_frameRate = fr,
			m_numOfFrame = totalNum,
			m_numOfX = numX,
			m_isRepeat = rep,
			m_initX = x,
			m_initY = y,
			m_dTime = 0,
			m_curFrame = 0
		}
		setmetatable(ret, AnimationComponent)
		return ret
	end,
	Name = function()
		return "AniCmp"
	end
}

AnimationComponent.__index = AnimationComponent

return AnimationComponent