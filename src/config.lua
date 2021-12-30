require "src/flags"

-- the size of the dungeon in cells
local dungeon_size = {
	["fine"] 		= 11,
	["dimin"] 		= 13,
	["tiny"] 		= 17,
	["small"] 		= 21,
	["medium"] 		= 27,
	["large"] 		= 35,
	["huge"] 		= 43,
	["gargant"] 	= 55,
	["colossal"] 	= 71,
}

return setmetatable({
	dungeon_size = dungeon_size,
}, {})