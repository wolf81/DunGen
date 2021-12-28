require 'src/config'

local Dungeon = {}
Dungeon.__index = Dungeon

function Dungeon:new(w, h, rooms)
	local cell = {}

	for x = 0, w do
		cell[x] = {}
		for y = 0, h do
			cell[x][y] = Flags.NOTHING
		end
	end

	for _, room in ipairs(rooms) do
		for x = room.x, room.x + room.w - 1 do
			for y = room.y, room.y + room.h - 1 do
				cell[x][y] = Flags.ROOM
			end
		end
	end

	return setmetatable({
		w = w,
		h = h,
		cell = cell,
	}, Dungeon)
end

function Dungeon:getCell(r, c)
	return self["cell"][r][c]
end

return setmetatable(Dungeon, {
	__call = Dungeon.new,
})