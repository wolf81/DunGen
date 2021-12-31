local Point = {}
Point.__index = Point

function Point:new(x, y)
	return setmetatable({
		x = x,
		y = y,
	}, Point)	
end

function Point:__eq(p)
	return self.x == p.x and self.y == p.y
end

function Point:__tostring()
	local s = "Point { "
	for k, v in pairs(self) do
		s = s .. "" .. k .. ": " .. tostring(v) .. ", "
	end
	s = s .. "}"

	return s
end

return setmetatable(Point, {
	__call = Point.new,
})