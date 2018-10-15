

local Entity = {
	a = 0,
	b = 0
}

function start(_ey)
	_ey.a = _ey.a + 1
	if (_ey.a >= 10) then
		_ey.b = 0
		print("to state1")
		return state1
	else
		return start
	end
end

function state1(_ey)
	_ey.b = _ey.b + 1
	if (_ey.b >= 10) then
		_ey.a = 0
		print("to start")
		return start
	else
		return state1
	end
end


function StateMachine(_ey, entry)
	local cur = entry
	for i=1,20 do
		cur = cur(_ey)
	end
end

StateMachine(Entity, start)