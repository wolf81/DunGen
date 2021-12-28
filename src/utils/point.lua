local Point = {}
Point.__index = Point

function Point:new(x, y)
	return setmetatable({
		x = x,
		y = y,
	}, Point)	
end

function Point:__tostring()
	local s = "Point {\n"
	for k, v in pairs(self) do
		s = s .. "\t" .. k .. ": " .. tostring(v) .. ",\n"
	end
	s = s .. "}"

	return s
end

return setmetatable(Point, {
	__call = Point.new,
})