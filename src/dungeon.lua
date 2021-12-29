require 'src/config'

local Dungeon = {}
Dungeon.__index = Dungeon

function Dungeon:new(w, h)
	local cells = {}

	for y = 0, h do
		cells[y] = {}
		for x = 0, w do
			cells[y][x] = Flags.NOTHING
		end
	end

	return setmetatable({
		w = w,
		h = h,
		_cells = cells,
	}, Dungeon)
end

function Dungeon:set_cell(x, y, value)
	self._cells[y][x] = value
end

function Dungeon:cell(x, y)
	return self._cells[y][x]
end

return setmetatable(Dungeon, {
	__call = Dungeon.new,
})