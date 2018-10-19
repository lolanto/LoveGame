-- sh: system hepler
-- etys: array of entities

local ac = 10

-- update userinput component according to user input state
function UserInputSystem(sh, etys)
	for i,v in ipairs(etys) do
			if (v.UsICmp ~= nil and v.VelCmp ~= nil) then
				local vmp = v.VelCmp
				local input = sh.input
				if input.up.pressed then vmp.m_acy = -ac
					elseif input.down.pressed then vmp.m_acy = ac
					else vmp.m_acy = 0
				end
				if input.left.pressed then vmp.m_acx = -ac
					elseif input.right.pressed then vmp.m_acx = ac
					else vmp.m_acx = 0
				end
			end
	end
end

return UserInputSystem