-- LuaJIT 2.1 required
local ffi = require'ffi'

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

Flags["OPENSPACE"] = bit.bor(Flags.ROOM, Flags.CORRIDOR)
Flags["DOORSPACE"] = bit.bor(Flags.ARCH, Flags.DOOR, Flags.LOCKED, Flags.TRAPPED, Flags.SECRET, Flags.PORTC)
Flags["ESPACE"] = bit.bor(Flags.ENTRANCE, Flags.DOORSPACE, 4278190080LL) -- why not Flags.LABEL?
Flags["STAIRS"] = bit.bor(Flags.STAIR_DN, Flags.STAIR_UP)
Flags["BLOCK_ROOM"] = bit.bor(Flags.BLOCKED, Flags.ROOM)
Flags["BLOCK_CORR"] = bit.bor(Flags.BLOCKED, Flags.PERIMETER, Flags.CORRIDOR)
Flags["BLOCK_DOOR"] = bit.bor(Flags.BLOCKED, Flags.DOORSPACE)
Flags["ROOM_ENTRANCE"] = bit.bor(Flags.ROOM, Flags.ENTRANCE)