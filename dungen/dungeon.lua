local _PATH = (...):match("(.-)[^%.]+$") 

local Config = require(_PATH .. ".config")

local Dungeon = {}
Dungeon.__index = Dungeon

function Dungeon:new(options)
	local dungeon_size = Config.dungeon_size[options["dungeon_size"]]
	local i, j = dungeon_size, dungeon_size

	-- the additional 2 is a bit weird here, but crashes otherwise 
	-- I guess used for the border?
	local rows = i * 2 + 2
	local cols = j * 2 + 2

	local cells = {}
	for r = 0, rows do
		cells[r] = {}
		for c = 0, cols do
			cells[r][c] = " "
		end
	end

	return setmetatable({
		n_i = i,
		n_j = j,
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

function Dungeon:toAscii()
	local s = ""

	for y = 0, self.rows do
		for x = 0, self.cols do
			local v = self._cells[y][x]
			s = s .. v
		end
		s = s .. "\n"
	end

	return s
end

return setmetatable(Dungeon, {
	__call = Dungeon.new,
})