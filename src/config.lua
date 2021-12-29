require "src/flags"

-- the size of the dungeon in cells
local dungeon_size = {
	["fine"] 		= 15,
	["dimin"] 		= 30,
	["tiny"] 		= 45,
	["small"] 		= 60,
	["medium"] 		= 75,
	["large"] 		= 90,
	["huge"] 		= 105,
	["gargant"] 	= 120,
	["colossal"] 	= 135,
}

local dungeon_layout = {
	["square"] = {
		["aspect"] = 1.0,
	},
	["rectangle"] = {
		["aspect"] = 1.3,		
	},
	["box"] = { 
		["mask"] = {
			{ 1, 1, 1 }, 
			{ 1, 0, 1 },
			{ 1, 1, 1 },			
		},
		["aspect"] = 1.0,
	},
	["cross"] = { 
		["mask"] = {
			{ 0, 1, 0 }, 
			{ 1, 1, 1 },
			{ 0, 1, 0 },			
		},
		["aspect"] = 1.0,
	},
	["keep"] = {
		["mask"] = {
			{ 1, 1, 0, 0, 1, 1 },
			{ 1, 1, 1, 1, 1, 1 },
			{ 0, 1, 1, 1, 1, 0 },
			{ 0, 1, 1, 1, 1, 0 },
			{ 1, 1, 1, 1, 1, 1 },
			{ 1, 1, 0, 0, 1, 1 },			
		},
		["aspect"] = 1.0,
	},
	["dagger"] = {
		["mask"] = {
			{ 0, 1, 0, 0 }, 
			{ 1, 1, 1, 1 },
			{ 0, 1, 0, 0 },
		}, 
		["aspect"] = 1.3,
	},
	["round"] = {
		["aspect"] = 1.0,	
	},
	["saltire"] = {
		["aspect"] = 1.0,		
	},
	["hexagon"] = {
		["aspect"] = 0.9,		
	}
}

local room_size = {
	["small"] 		= { ["size"] = 2, ["radix"] = 2 },
	["medium"] 		= { ["size"] = 2, ["radix"] = 5 },
	["large"] 		= { ["size"] = 5, ["radix"] = 2 },
	["huge"] 		= { ["size"] = 5, ["radix"] = 5 },
	["gargant"] 	= { ["size"] = 8, ["radix"] = 5 },
	["colossal"] 	= { ["size"] = 8, ["radix"] = 8 },
}

local room_layout = {
	["sparse"] 		= { ["complex"] = false }, 
	["scattered"] 	= { ["complex"] = true }, 
	["dense"] 		= { ["complex"] = false },
}

local doors = {
	["none"] = {
		{ 15, 	Flags.ARCH },
	},
	["basic"] = {
		{ 15, 	Flags.ARCH },
		{ 60, 	Flags.DOOR },
	},
	["secure"] = {
		{ 15, 	Flags.ARCH },
		{ 60, 	Flags.DOOR },
		{ 75, 	Flags.LOCKED },		
	},
	["standard"] = {
		{ 15, 	Flags.ARCH },
		{ 60, 	Flags.DOOR },
		{ 75, 	Flags.LOCKED },
		{ 90, 	Flags.TRAPPED },
		{ 100, 	Flags.SECRET },
		{ 110, 	Flags.PORTC },
	},
	["deathtrap"] = {
		{ 15, 	Flags.ARCH },
		{ 30, 	Flags.TRAPPED },
		{ 40, 	Flags.SECRET },
	},
}

local corridor_layout = {
	["labyrinth"] 	= 0,
	["errant"] 		= 50,
	["straight"] 	= 90,	
}

local remove_deadends = {
	["none"] 		= 0,
	["some"] 		= 50,
	["all"] 		= 100,
}

local add_stairs = {
	["no"] 			= 0,
	["yes"] 		= 2,
	["many"] 		= math.huge,
}

return setmetatable({
	dungeon_layout = dungeon_layout,
	dungeon_size = dungeon_size,
	room_layout = room_layout,
	room_size = room_size,
	corridor_layout = corridor_layout,
	remove_deadends = remove_deadends,
	add_stairs = add_stairs,
	doors = doors,
}, {})