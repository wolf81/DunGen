local Point = require 'src/utils/point'

local Corridor = {}
Corridor.__index = Corridor

function Corridor:new(rect)
	local points = {}

	if rect ~= nil then
		local x1 = rect.x + math.random(0, math.floor(rect.w / 3))
		local y1 = rect.y + math.random(0, math.floor(rect.h / 3))
		local w = rect.w - (x1 - rect.x) - 1
		local h = rect.h - (y1 - rect.y) - 1
		local x2 = x1 + w - math.floor(math.random(0, w / 3))
		local y2 = y1 + h - math.floor(math.random(0, h / 3))

		local dir = math.random(0, 1)
		if dir == 0 then
			points[#points + 1] = Point(x1, y1)
			points[#points + 1] = Point(x1, y2)
			points[#points + 1] = Point(x2, y2)
		else
			points[#points + 1] = Point(x1, y1)
			points[#points + 1] = Point(x2, y1)
			points[#points + 1] = Point(x2, y2)
		end
	end

	return setmetatable({
		_points = points,
	}, Corridor)
end

function Corridor:add_point(point)	
	local key = point.x..','..point.y

	if self._points[key] ~= nil then return end
	
	self._points[key] = point
end

function Corridor:points()
	return self._points
end

return setmetatable(Corridor, {
	__call = Corridor.new
})