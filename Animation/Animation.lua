local function CheckNumber(v)
	assert(type(v) == "number", "parameter is not number")
end

AnimationComponent = {
	Create = function(img, x, y, width, height, totalNum, fr, rep, numX)
		rep = rep or false
		numX = numX or nil
		-- parameter checking!
		assert(img:type() == "Image", "parameter is not img")
		CheckNumber(x); CheckNumber(y); CheckNumber(width); CheckNumber(height);
		CheckNumber(totalNum); CheckNumber(fr)
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

AnimationSystem = function(sh, etys)
	for i,v in ipairs(etys) do
		if (v.AniCmp ~= nil and v.AniCmp.Name() == "AniCmp") then
			local cmp = v.AniCmp
			cmp.m_dTime = cmp.m_dTime + sh.deltaTime
			if (cmp.m_dTime > cmp.m_frameRate) then
				cmp.m_dTime = 0
				cmp.m_curFrame = cmp.m_curFrame + 1
				-- switching to next frame
				x, y, w, h = cmp.m_quad:getViewport()
				if (cmp.m_curFrame == cmp.m_numOfFrame) then
					if (cmp.m_isRepeat) then cmp.m_curFrame = -(cmp.m_numOfFrame - 1)
					else cmp.m_curFrame = 0
					end
				end
				vx = math.abs(cmp.m_curFrame)
				vy = 0
				if (cmp.m_numOfX) then
					vy = math.floor(vx / cmp.m_numOfX)
					vx = vx % cmp.m_numOfX
				end
				x = cmp.m_initX + vx * w
				y = cmp.m_initY + vy * h
				cmp.m_quad:setViewport(x, y, w, h)
				-- end of switching to next frame
			end
			table.insert(sh.drawCall, function() love.graphics.draw(cmp.m_img, cmp.m_quad, 0, 0) end)
		end
	end
end
--[[

--]]

return {
	Component = AnimationComponent,
	System = AnimationSystem
}