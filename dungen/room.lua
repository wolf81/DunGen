local _PATH = (...):match("(.-)[^%.]+$") 

local Point = require(_PATH .. ".point")

local Room = {}
Room.__index = Room

function Room:new(x, y, w, h)
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

function Room:contains_point(p)
	return p.x > self.x and p.x < self.x + self.w and p.y > self.y and p.y < self.y + self.h
end

function Room:__tostring()
	local s = "Room {\n"
	for k, v in pairs(self) do
		s = s .. "\t" .. k .. ": " .. tostring(v) .. ",\n"
	end
	s = s .. "}"

	return s
end

return setmetatable(Room, {
	__call = Room.new
})