Flags = {
	["NOTHING"] = 0LL, 			-- 0x00000000
	
	["BLOCKED"] = 1LL,  		-- 0x00000001
	["ROOM"] = 2LL,				-- 0x00000002
	["CORRIDOR"] = 4LL,			-- 0x00000004

	["PERIMETER"] = 16LL,		-- 0x00000010
	["ENTRANCE"] = 32LL,		-- 0x00000020
	["ROOM_ID"] = 65472LL,		-- 0x0000FFC0

	["ARCH"] = 65536LL,			-- 0x00010000
	["DOOR"] = 131072LL,		-- 0x00020000
	["LOCKED"] = 262144LL,		-- 0x00040000
	["TRAPPED"] = 524288LL,		-- 0x00080000
	["SECRET"] = 1048576LL,		-- 0x00100000
	["PORTC"] = 2097152LL,		-- 0x00200000
	["STAIR_DN"] = 4194304LL,	-- 0x00400000
	["STAIR_UP"] = 8388608LL,	-- 0x00800000

	["LABEL"] = 4278190080LL,	-- 0xFF000000
}

local openspace = bit.bor(Flags.ROOM, Flags.CORRIDOR)
local doorspace = bit.bor(Flags.ARCH, Flags.DOOR, Flags.LOCKED, Flags.TRAPPED, Flags.SECRET, Flags.PORTC)
local espace = bit.bor(Flags.ENTRANCE, doorspace, Flags.LABEL)
local stairs = bit.bor(Flags.STAIR_DN, Flags.STAIR_UP)
local block_room = bit.bor(Flags.BLOCKED, Flags.ROOM)
local block_corr = bit.bor(Flags.BLOCKED, Flags.PERIMETER, Flags.CORRIDOR)
local block_door = bit.bor(Flags.BLOCKED, doorspace)
local room_entrance = bit.bor(Flags.ROOM, Flags.ENTRANCE)

Mask = {
	openspace = openspace,
	doorspace = doorspace,
	espace = espace,
	stairs = stairs,
	block_room = block_room,
	block_corr = block_corr,
	block_door = block_door,
	room_entrance = room_entrance,
}