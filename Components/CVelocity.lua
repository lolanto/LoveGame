VelocityComponent = {
	Create = function()
		local ret = {
			m_vx = 0,
			m_vy = 0, -- current velocity in x/y direction
			m_acx = 0, -- acceleration
			m_acy = 0
		}
		setmetatable(ret, VelocityComponent)
		return ret
	end,
	Name = function()
		return "VelCmp"
	end
}

VelocityComponent.__index = VelocityComponent

return VelocityComponent