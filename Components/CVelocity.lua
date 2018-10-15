VelocityComponent = {
	Create = function()
		local ret = {
			m_vx = 0,
			m_vy = 0, -- current velocity in x/y direction
			m_ac = 0 -- acceleration
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