require 'src/config'

local Config = require 'src/config'

local mfloor = math.floor

local Dungeon = {}
Dungeon.__index = Dungeon

function Dungeon:new(options)
	local this = {}

    for k, v in pairs(options) do
    	this[k] = v
    end

	local dungeon_size = Config.dungeon_size[options["dungeon_size"]]
	local dungeon_layout = Config.dungeon_layout[options["dungeon_layout"]]	
	local aspect = dungeon_layout["aspect"]
    local n_i, n_j = dungeon_size, mfloor(dungeon_size * aspect)
    if n_i % 2 == 0 then n_i = n_i - 1 end

	this["n_i"] = n_i
	this["n_j"] = n_j
	this["n_rows"] = n_i * 2
	this["n_cols"] = n_j * 2
	this["max_row"] = this["n_rows"] - 1
	this["max_col"] = this["n_cols"] - 1
	this["n_rooms"] = 0
	this["room"] = {}
	this["door"] = {}
	this["stair"] = {}
	this["cell"] = {}

	for r = 0, this["n_rows"] do
		this["cell"][r] = {}
		for c = 0, this["n_cols"] do
			this["cell"][r][c] = Flags.NOTHING
		end
	end

	return setmetatable(this, Dungeon)
end

function Dungeon:getCell(r, c)
	if r >= 0 and r <= self["max_row"] and c >= 0 and c <= self["max_col"] then
		return self["cell"][r][c]
	end

	return Flags.NOTHING
end

return setmetatable(Dungeon, {
	__call = Dungeon.new,
})