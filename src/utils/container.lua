local Point = require 'src/utils/point'

local Container = {}
Container.__index = Container

function Container:new(x, y, w, h)
	return setmetatable({
		x = x,
		y = y,
		w = w,
		h = h,
		center = Point(x + w / 2, y + h / 2),
	}, Container)
end

function Container:__tostring()
	local s = "Container {\n"
	for k, v in pairs(self) do
		s = s .. "\t" .. k .. ": " .. tostring(v) .. ",\n"
	end
	s = s .. "}"

	return s
end

return setmetatable(Container, {
	__call = Container.new
})