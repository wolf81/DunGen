local Point = require 'src/utils/point'

local Corridor = {}
Corridor.__index = Corridor

local function generate_points(container)
	local x1 = container.x + math.random(0, container.w)
	local y1 = container.y + math.random(0, container.h)
	local x2 = container.x + math.random(0, container.w)
	local y2 = container.y + math.random(0, container.h)

	local d = math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2))
	local d_min = math.min(container.w / 2, container.h / 2)

	if d_min < 1 then error("distance too small") end

	if d < d_min then
		return generate_points(container)
	end

	return x1, y1, x2, y2
end

function Corridor:new(container)
	local points = {}

	if container ~= nil then
		local x1, y1, x2, y2 = generate_points(container)

		local dir = math.random(0, 1)
		if dir == 0 then
			local step = x2 > x1 and 1 or -1
			for x = x1, x2, step do
				points[#points + 1] = Point(x, y1)
			end
			step = y2 > y1 and 1 or -1
			for y = y1 + step, y2 do
				points[#points + 1] = Point(x2, y)				
			end
		else
			local step = y2 > y1 and 1 or -1
			for y = y1, y2, step do
				points[#points + 1] = Point(x1, y)
			end
			step = x2 > x1 and 1 or -1
			for x = x1 + step, x2 do
				points[#points + 1] = Point(x, y2)				
			end
		end

		for _, p in ipairs(points) do
			print(p)
		end
	end

	return setmetatable({
		_points = points
	}, Corridor)
end

function Corridor:random_point()
	return self._points[math.random(#self._points)]
end

function Corridor:add_point(point)
	local skip = false
	for _, p in ipairs(self._points) do
		if p.x == point.x and p.y == point.y then
			skip = true
			break
		end
	end

	if not skip then
		self._points[#self._points + 1] = point
	end
end

function Corridor:points()
	return self._points
end

return setmetatable(Corridor, {
	__call = Corridor.new
})