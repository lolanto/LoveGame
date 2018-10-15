-- position component
PositionComponent = {
	Create = function(cx, cy)
		local ret = {
			m_x = cx,
			m_y = cy
		}
		setmetatable(ret, PositionComponent)
		return ret
	end,
	GetX = function (cmp) return cmp.m_x end,
	GetY = function (cmp) return cmp.m_y end,
	Name = function()
		return "PosCmp"
	end
}

PositionComponent.__index = PositionComponent

return PositionComponent