require "src/flags"

DungeonSize = {
	fine 		= 11,
	dimin 		= 13,
	tiny 		= 17,
	small 		= 21,
	medium 		= 27,
	large 		= 35,
	huge 		= 43,
	gargant 	= 55,
	colossal 	= 71,
}

DungeonLayout = {
	square = { 
		aspect = 1.0,
	},
	rectangle = {
		aspect = 1.3,
	},
	box = {
		aspect = 1.0,
		mask = {
			{ 1, 1, 1 },
			{ 1, 0, 1 },
			{ 1, 1, 1 },
		},
	},
	cross = {
		aspect = 1.0,
		mask = {
			{ 0, 1, 0 },
			{ 1, 1, 1 },
			{ 0, 1, 0 },
		},
	},
	keep = {
		aspect = 1.0,
		mask = {
			{ 1, 1, 0, 0, 1, 1 },
			{ 1, 1, 1, 1, 1, 1 },
			{ 0, 1, 1, 1, 1, 0 },
			{ 0, 1, 1, 1, 1, 0 },
			{ 1, 1, 1, 1, 1, 1 },
			{ 1, 1, 0, 0, 1, 1 },			
		},
	},
	dagger = {
		aspect = 1.0,
		mask = {
			{ 0, 1, 0, 0 }, 
			{ 1, 1, 1, 1 },
			{ 0, 1, 0, 0 },			
		},
	},
	round = {
		aspect = 1.0,
	},
	saltire = {
		aspect = 1.0,
	}, 
	hexagon = {
		aspect = 0.9,
	},
}

RoomSize = {
	small =		{ size = 2, radix = 2, huge = false },
	medium = 	{ size = 2, radix = 5, huge = false },
	large = 	{ size = 5, radix = 2, huge = false },
	huge = 		{ size = 5, radix = 5, huge = true },
	gargant = 	{ size = 8, radix = 5, huge = true },
	colossal = 	{ size = 8, radix = 8, huge = true },
}

RoomLayout = {
	sparse = { complex = false },
	scattered = { complex = true },
	dense = { complex = false },
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

CorridorLayout = {
	labyrinth 	= 0,
	errant 		= 50,
	straight 	= 90,	
}

RemoveDeadends = {
	none 		= 0,
	some 		= 50,
	all 		= 100,
}

AddStairs = {
	no 			= 0,
	yes 		= 2,
	many 		= math.huge,
}

return setmetatable({
	doors = doors,
}, {})