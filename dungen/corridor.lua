local _PATH = (...):match("(.-)[^%.]+$") 

local Point = require(_PATH .. ".point")
local Set = require(_PATH .. "set")

local Corridor = {}
Corridor.__index = Corridor

function Corridor:new(points)
	local points_set = Set()

	for _, p in ipairs(points) do
		points_set:add(p)
	end

	return setmetatable({
		_points = points_set,
	}, Corridor)
end

function Corridor:add_point(point)	
	self._points:add(point)
end

function Corridor:points()
	return self._points:values()
end

function Corridor:random_point()
	local p_size = self._points:size()
	local p_idx = math.random(1, p_size)
	return self._points:get(p_idx)
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