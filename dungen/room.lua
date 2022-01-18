local _PATH = (...):match("(.-)[^%.]+$") 

local Point = require(_PATH .. ".point")

local Room = {}
Room.__index = Room

function Room:new(rect)
	local x = rect.x + math.random(0, math.floor(rect.w / 3))
	local y = rect.y + math.random(0, math.floor(rect.h / 3))
	local w = rect.w - (x - rect.x)
	local h = rect.h - (y - rect.y)
	w = w - math.floor(math.random(0, w / 3))
	h = h - math.floor(math.random(0, h / 3))
	return setmetatable({
		x = x,
		y = y,
		w = w, 
		h = h,
	}, Room)
end

function Room:random_point()
	local x = math.random(self.x, self.x + self.w - 1)
	local y = math.random(self.y, self.y + self.h - 1)
	return Point(x, y)
end

function Room:__tostring()
	local s = "Room {\n"
	for k, v in pairs(self) do
		s = s .. "\t" .. k .. ": " .. tostring(v) .. ",\n"
	end
	s = s .. "}"

	return s
end

function Room:is_a(class)
	return getmetatable(self) == class
end

return setmetatable(Room, {
	__call = Room.new
})