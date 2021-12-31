local Point = require 'src/utils/point'
local Set = require 'src/utils/set'

local Corridor = {}
Corridor.__index = Corridor

function Corridor:new(rect)
	local points = Set()

	if rect ~= nil then
		local x1 = rect.x + math.random(0, math.floor(rect.w / 3))
		local y1 = rect.y + math.random(0, math.floor(rect.h / 3))
		local w = rect.w - (x1 - rect.x) - 1
		local h = rect.h - (y1 - rect.y) - 1
		local x2 = x1 + w - math.floor(math.random(0, w / 3))
		local y2 = y1 + h - math.floor(math.random(0, h / 3))

		local dir = math.random(0, 1)
		if dir == 0 then
			for y = y1, y2 do
				points:add(Point(x1, y))
			end
			for x = x1, x2 do
				points:add(Point(x, y2))
			end
		else
			for x = x1, x2 do
				points:add(Point(x, y1))
			end
			for y = y1, y2 do
				points:add(Point(x2, y))
			end
		end
	end

	return setmetatable({
		_points = points,
	}, Corridor)
end

function Corridor:add_point(point)	
	self._points:add(point)
end

function Corridor:points()
	return self._points:values()
end

function Corridor:random_point()
	-- local points = {}
	-- local last_point = nil
	-- for _, p in ipairs(self._points) do
	-- 	if p. ~= last_point then

	-- 	end
	-- end
end

function Corridor:__tostring()
	local s = "Corridor { "
	for k, v in pairs(self) do
		s = s .. "" .. k .. ": " .. tostring(v) .. ", "
	end
	s = s .. "}"

	return s
end

return setmetatable(Corridor, {
	__call = Corridor.new
})