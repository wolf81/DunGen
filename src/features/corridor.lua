local Corridor = {}
Corridor.__index = Corridor

function Corridor:new()
	return setmetatable({
		_points = {},
	}, Corridor)
end

function Corridor:add_point(point)	
	local key = point.x..','..point.y

	if self._points[key] ~= nil then return end
	
	self._points[key] = point
end

function Corridor:points()
	-- body
end

return setmetatable(Corridor, {
	__call = Corridor.new
})