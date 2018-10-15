AnimationSystem = function(sh, etys)
	for i,v in ipairs(etys) do
		-- should have animation component and position component
		if (v.AniCmp ~= nil and v.PosCmp ~= nil) then
			local cmp = v.AniCmp
			cmp.m_dTime = cmp.m_dTime + sh.deltaTime
			x, y, w, h = cmp.m_quad:getViewport()
			if (cmp.m_dTime > cmp.m_frameRate) then
				cmp.m_dTime = 0
				cmp.m_curFrame = cmp.m_curFrame + 1
				-- switching to next frame
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
			table.insert(sh.drawCall, function()
					love.graphics.draw(cmp.m_img, cmp.m_quad, 
						v.PosCmp:GetX() - w / 2.0, v.PosCmp:GetY() - h / 2.0)
				end)
		end
	end
end

return AnimationSystem