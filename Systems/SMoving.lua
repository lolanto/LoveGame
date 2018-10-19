-- sh: system helper
-- etys: array of entities
function MovingSystem(sh, etys)
	for i,v in ipairs(etys) do
		if (v.VelCmp ~= nil and v.PosCmp) then
			local vmp = v.VelCmp
			local pmp = v.PosCmp
			vmp.m_vx = vmp.m_vx + vmp.m_acx * sh.deltaTime
			vmp.m_vy = vmp.m_vy + vmp.m_acy * sh.deltaTime
			pmp.m_x = pmp.m_x + vmp.m_vx * sh.deltaTime
			pmp.m_y = pmp.m_y + vmp.m_vy * sh.deltaTime
		end
	end
end

return MovingSystem