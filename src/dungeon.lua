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

	return setmetatable(this, Dungeon)
end

return setmetatable(Dungeon, {
	__call = Dungeon.new
})