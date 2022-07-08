require 'src/config'

local Config = require 'src/config'

local mfloor = math.floor

local Dungeon = {}
Dungeon.__index = Dungeon

function Dungeon:new(options)
	local self = {}

    for k, v in pairs(options) do
    	self[k] = v
    end

	local dungeon_size = DungeonSize[options.dungeon_size]
	local dungeon_layout = DungeonLayout[options.dungeon_layout]	
	local aspect = dungeon_layout.aspect
    local n_i, n_j = dungeon_size, mfloor(dungeon_size * aspect)
    local n_rows, n_cols = n_i * 2, n_j * 2
    local cell = {}

	self.n_i = n_i
	self.n_j = n_j
	self.n_rows = n_i * 2
	self.n_cols = n_j * 2
	self.max_row = self.n_rows - 1
	self.max_col = self.n_cols - 1
	self.n_rooms = 0
	self.room = {}
	self.door = {}
	self.stair = {}
	self.cell = {}

	for r = 0, self.n_rows do
		self.cell[r] = {}
		for c = 0, self.n_cols do
			self.cell[r][c] = Flag.NOTHING
		end
	end

	return setmetatable(self, Dungeon)
end

function Dungeon:getCell(r, c)
	if r >= 0 and r <= self.max_row and c >= 0 and c <= self.max_col then
		return self.cell[r][c]
	end

	return Flag.NOTHING
end

return setmetatable(Dungeon, {
	__call = Dungeon.new,
})