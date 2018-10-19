-- user input component

UserInputComponent = {
	Create = function()
		local ret = {}
		setmetatable(ret, UserInputComponent)
		return ret
	end,
	Name = function()
		return "UsICmp"
	end
}

UserInputComponent.__index = UserInputComponent
return UserInputComponent