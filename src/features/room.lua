local Room = {}
Room.__index = Room

function Room:new(container)
	local x = container.x + math.random(0, math.floor(container.w / 3))
	local y = container.y + math.random(0, math.floor(container.h / 3))
	local w = container.w - (x - container.x) - 1
	local h = container.h - (y - container.y) - 1
	w = w - math.floor(math.random(0, w / 3))
	h = h - math.floor(math.random(0, h / 3)) -- or w / 3 ?
	return setmetatable({
		x = x,
		y = y,
		w = w, 
		h = h,
	}, Room)
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