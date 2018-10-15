Entity = {
	Create = function()
		local ret = {}
		setmetatable(ret, Entity)
		return ret
	end,
	AddComponent = function(e, cmp)
		e[cmp.Name()] = cmp
		return e
	end
}
Entity.__index = Entity

return Entity