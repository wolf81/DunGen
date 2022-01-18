local _PATH = (...):match("(.-)[^%.]+$") 

local Point = require(_PATH .. "point")

local Rect = {}
Rect.__index = Rect

function Rect:new(x, y, w, h)
	return setmetatable({
		x = x,
		y = y,
		w = w,
		h = h,
		center = Point(x + math.floor(w / 2), y + math.floor(h / 2)),
	}, Rect)
end

function Rect:__tostring()
	local s = "Rect {\n"
	for k, v in pairs(self) do
		s = s .. "\t" .. k .. ": " .. tostring(v) .. ",\n"
	end
	s = s .. "}"

	return s
end

return setmetatable(Rect, {
	__call = Rect.new
})