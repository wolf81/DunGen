local Config = require 'src/config'

local Dungeon = {}
Dungeon.__index = Dungeon

function Dungeon:new(options)
	local dungeon_size = Config.dungeon_size[options["dungeon_size"]]
	local i, j = dungeon_size, dungeon_size

	local rows = i * 2 + 1
	local cols = j * 2 + 1

	local cells = {}
	for r = 0, rows do
		cells[r] = {}
		for c = 0, cols do
			cells[r][c] = Flags.NOTHING
		end
	end

	return setmetatable({
		_i = i,
		_j = j,
		rows = rows,
		cols = cols,
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