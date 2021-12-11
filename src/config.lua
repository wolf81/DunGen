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

local dungeon_layout = {
	["square"] = {
		["aspect"] = 1.0,
	},
	["rectangle"] = {
		["aspect"] = 1.3,		
	},
	["box"] = { 
		["mask"] = {
			[0] = 
				{ [0] = 1, 1, 1 }, 
				{ [0] = 1, 0, 1 },
				{ [0] = 1, 1, 1 },			
		},
		["aspect"] = 1.0,
	},
	["cross"] = { 
		["mask"] = {
			[0] = 
				{ [0] = 0, 1, 0 }, 
				{ [0] = 1, 1, 1 },
				{ [0] = 0, 1, 0 },			
		},
		["aspect"] = 1.0,
	},
	["keep"] = {
		["mask"] = {
			[0] =
				{ [0] = 1, 1, 0, 0, 1, 1 },
				{ [0] = 1, 1, 1, 1, 1, 1 },
				{ [0] = 0, 1, 1, 1, 1, 0 },
				{ [0] = 0, 1, 1, 1, 1, 0 },
				{ [0] = 1, 1, 1, 1, 1, 1 },
				{ [0] = 1, 1, 0, 0, 1, 1 },			
		},
		["aspect"] = 1.0,
	},
	["dagger"] = {
		["mask"] = {
			[0] = 
				{ [0] = 0, 1, 0, 0 }, 
				{ [0] = 1, 1, 1, 1 },
				{ [0] = 0, 1, 0, 0 },
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
	["small"] 		= { ["size"] = 2, ["radix"] = 2, ["huge"] = false },
	["medium"] 		= { ["size"] = 2, ["radix"] = 5, ["huge"] = false },
	["large"] 		= { ["size"] = 5, ["radix"] = 2, ["huge"] = false },
	["huge"] 		= { ["size"] = 5, ["radix"] = 5, ["huge"] = true  },
	["gargant"] 	= { ["size"] = 8, ["radix"] = 5, ["huge"] = true  },
	["colossal"] 	= { ["size"] = 8, ["radix"] = 8, ["huge"] = true  },
}

local room_layout = {
	["sparse"] 		= { ["complex"] = false }, 
	["scattered"] 	= { ["complex"] = true }, 
	["dense"] 		= { ["complex"] = false },
}

local doors = {
	["none"] 		= {},
	["basic"] 		= {},
	["secure"] 		= {},
	["standard"] 	= {},
	["deathtrap"] 	= {},
}

local corridor_layout = {
	["Labyrinth"] 	= 0,
	["Bent"] 		= 50,
	["Straight"] 	= 100,	
}

return setmetatable({
	dungeon_layout = dungeon_layout,
	dungeon_size = dungeon_size,
	room_layout = room_layout,
	room_size = room_size,
	corridor_layout = corridor_layout,
	doors = doors,
}, {})