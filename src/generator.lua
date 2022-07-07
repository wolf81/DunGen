require 'src/flags'

local Config = require 'src/config'
local BitMask = require 'src/bitmask'
local Dungeon = require 'src/dungeon'

local bset, bclear, bcheck = BitMask.set, BitMask.clear, BitMask.check
local mfloor, mrandom, msqrt, mpow = math.floor, math.random, math.sqrt, math.pow
local mmax, mmin, mabs, mhuge = math.max, math.min, math.abs, math.huge

-- directions
local di = { ["north"] = -1, ["south"] = 1, ["west"] =  0, ["east"] = 0 }
local dj = { ["north"] =  0, ["south"] = 0, ["west"] = -1, ["east"] = 1 }

local opposite = {
	["north"] 	= "south",
	["south"] 	= "north",
	["east"] 	= "west",
	["west"] 	= "east",
}

local stair_end = {
    ["north"] = {
        ["walled"]		= {{1,-1},{0,-1},{-1,-1},{-1,0},{-1,1},{0,1},{1,1}},
        ["corridor"]	= {{0,0},{1,0},{2,0}},
        ["stair"]		= {0,0},
        ["next"]		= {1,0},
    },
    ["south"] = {
        ["walled"]		= {{-1,-1},{0,-1},{1,-1},{1,0},{1,1},{0,1},{-1,1}},
        ["corridor"]	= {{0,0},{-1,0},{-2,0}},
        ["stair"]		= {0,0},
        ["next"]		= {-1,0},
    },
    ["west"] = {
        ["walled"]		= {{-1,1},{-1,0},{-1,-1},{0,-1},{1,-1},{1,0},{1,1}},
        ["corridor"]	= {{0,0},{0,1},{0,2}},
        ["stair"]		= {0,0},
        ["next"]		= {0,1},
    },
    ["east"] = {
        ["walled"]		= {{-1,-1},{-1,0},{-1,1},{0,1},{1,1},{1,0},{1,-1}},
        ["corridor"]	= {{0,0},{0,-1},{0,-2}},
        ["stair"]		= {0,0},
        ["next"]		= {0,-1},
    },
}

local close_arcs = {
	["north-west"] = {
        ["corridor"] 	= {{0,0},{-1,0},{-2,0},{-2,-1},{-2,-2},{-1,-2},{0,-2}},
        ["walled"] 		= {{-1,1},{-2,1},{-3,1},{-3,0},{-3,-1},{-3,-2},{-3,-3},{-2,-3},{-1,-3},{0,-1},{-1,-1}},
        ["close"] 		= {{-1,0},{-2,0},{-2,-1},{-2,-2},{-1,-2}},
        ["open"] 		= {0,-1},
        ["recurse"] 	= {2,0},
    },
    ["north-east"] = {
        ["corridor"] 	= {{0,0},{-1,0},{-2,0},{-2,1},{-2,2},{-1,2},{0,2}},
        ["walled"] 		= {{-1,-1},{-2,-1},{-3,-1},{-3,0},{-3,1},{-3,2},{-3,3},{-2,3},{-1,3},{0,1},{-1,1}},
        ["close"] 		= {{-1,0},{-2,0},{-2,1},{-2,2},{-1,2}},
        ["open"] 		= {0,1},
        ["recurse"] 	= {2,0},
    },
    ["south-west"] = {
        ["corridor"] 	= {{0,0},{1,0},{2,0},{2,-1},{2,-2},{1,-2},{0,-2}},
        ["walled"] 		= {{1,1},{2,1},{3,1},{3,0},{3,-1},{3,-2},{3,-3},{2,-3},{1,-3},{0,-1},{1,-1}},
        ["close"] 		= {{1,0},{2,0},{2,-1},{2,-2},{1,-2}},
        ["open"] 		= {0,-1},
        ["recurse"] 	= {-2,0}
    },
    ["south-east"] = {
        ["corridor"] 	= {{0,0},{1,0},{2,0},{2,1},{2,2},{1,2},{0,2}},
        ["walled"] 		= {{1,-1},{2,-1},{3,-1},{3,0},{3,1},{3,2},{3,3},{2,3},{1,3},{0,1},{1,1}},
        ["close"] 		= {{1,0},{2,0},{2,1},{2,2},{1,2}},
        ["open"] 		= {0,1},
        ["recurse"] 	= {-2,0},
    },
    ["west-north"] = {
        ["corridor"] 	= {{0,0},{0,-1},{0,-2},{-1,-2},{-2,-2},{-2,-1},{-2,0}},
        ["walled"] 		= {{1,-1},{1,-2},{1,-3},{0,-3},{-1,-3},{-2,-3},{-3,-3},{-3,-2},{-3,-1},{-1,0},{-1,-1}},
        ["close"] 		= {{0,-1},{0,-2},{-1,-2},{-2,-2},{-2,-1}},
        ["open"] 		= {-1,0},
        ["recurse"] 	= {0,2},
    },
    ["west-south"] = {
        ["corridor"] 	= {{0,0},{0,-1},{0,-2},{1,-2},{2,-2},{2,-1},{2,0}},
        ["walled"] 		= {{-1,-1},{-1,-2},{-1,-3},{0,-3},{1,-3},{2,-3},{3,-3},{3,-2},{3,-1},{1,0},{1,-1}},
        ["close"] 		= {{0,-1},{0,-2},{1,-2},{2,-2},{2,-1}},
        ["open"] 		= {1,0},
        ["recurse"] 	= {0,2},
    },
    ["east-north"] = {
        ["corridor"] 	= {{0,0},{0,1},{0,2},{-1,2},{-2,2},{-2,1},{-2,0}},
        ["walled"] 		= {{1,1},{1,2},{1,3},{0,3},{-1,3},{-2,3},{-3,3},{-3,2},{-3,1},{-1,0},{-1,1}},
        ["close"] 		= {{0,1},{0,2},{-1,2},{-2,2},{-2,1}},
        ["open"] 		= {-1,0},
        ["recurse"] 	= {0,-2},
    },
    ["east-south"] = {
        ["corridor"] 	= {{0,0},{0,1},{0,2},{1,2},{2,2},{2,1},{2,0}},
        ["walled"] 		= {{-1,1},{-1,2},{-1,3},{0,3},{1,3},{2,3},{3,3},{3,2},{3,1},{1,0},{1,1}},
        ["close"] 		= {{0,1},{0,2},{1,2},{2,2},{2,1}},
        ["open"] 		= {1,0},
        ["recurse"] 	= {0,-2},
    }
}

local close_end = {
    ["north"] = {
        ["walled"]		= {{0,-1},{1,-1},{1,0},{1,1},{0,1}},
        ["close"]		= {{0,0}},
        ["recurse"]		= {-1,0},
    },
    ["south"] = {
        ["walled"]		= {{0,-1},{-1,-1},{-1,0},{-1,1},{0,1}},
        ["close"]		= {{0,0}},
        ["recurse"]		= {1,0},
    },
    ["west"] = {
        ["walled"]		= {{-1,0},{-1,1},{0,1},{1,1},{1,0}},
        ["close"]		= {{0,0}},
        ["recurse"]		= {0,-1},
    },
    ["east"] = {
        ["walled"]		= {{-1,0},{-1,-1},{0,-1},{1,-1},{1,0}},
        ["close"]		= {{0,0}},
        ["recurse"]		= {0,1},
    },
}

local function getDoorType(dungeon)
	local doorTypes = Config.doors[dungeon["doors"]]
	local max = doorTypes[#doorTypes][1]

	local value = mfloor(mrandom(max))
	local door = Flags.ARCH

	for _, doorType in ipairs(doorTypes) do
		if doorType[1] >= value then break end
		door = doorType[2]
	end

	return door
end

local function maskCells(dungeon, mask)
	local r_x = #mask * 1.0 / (dungeon["n_rows"])
	local c_x = #mask[1] * 1.0 / (dungeon["n_cols"])
	local cell = dungeon["cell"]

	for r = 0, dungeon["n_rows"] - 1 do
		for c = 0, dungeon["n_cols"] - 1 do
			local y = mfloor(r * r_x + 1.0)
			local x = mfloor(c * c_x + 1.0)
			cell[r][c] = (mask[y][x] == 1 and Flags.NOTHING or Flags.BLOCKED)
		end
	end
end

local function saltireMask(dungeon)
	local cell = dungeon["cell"]

	local i_max = mfloor(dungeon["n_rows"] / 4)
	for i = 0, i_max - 1 do
		local j = i + i_max
		local j_max = dungeon["n_cols"] - j

		for j = j, j_max do
			cell[i][j] = Flags.BLOCKED
			cell[dungeon["n_rows"] - i][j] = Flags.BLOCKED
			cell[j][i] = Flags.BLOCKED
			cell[j][dungeon["n_cols"] - i] = Flags.BLOCKED
		end
	end
end

local function hexagonMask(dungeon)
	local cell = dungeon["cell"]

	local r_half = dungeon["n_rows"] / 2
	for r = 0, dungeon["n_rows"] do
		local c_min = mfloor(mabs(r - r_half) * 0.57735)
		local c_max = dungeon["n_cols"] - c_min

		for c = 0, dungeon["n_cols"] do
			if c < c_min or c > c_max then
				cell[r][c] = Flags.BLOCKED
			end
		end
	end
end

local function roundMask(dungeon)
	local center_r = mfloor(dungeon["n_rows"] / 2)
	local center_c = mfloor(dungeon["n_cols"] / 2)
	local cell = dungeon["cell"]

	for r = 0, dungeon["n_rows"] do
		for c = 0, dungeon["n_cols"] do
			local d = msqrt(
				mpow((r - center_r), 2) + 
				mpow((c - center_c), 2))
			cell[r][c] = d > center_c and Flags.BLOCKED or Flags.NOTHING
		end
	end
end

local function applyLayout(dungeon)
	local layout = dungeon["dungeon_layout"]
	if layout == "round" then
		roundMask(dungeon)
	elseif layout == "saltire" then
		saltireMask(dungeon)
	elseif layout == "hexagon" then
		hexagonMask(dungeon)
	elseif DungeonLayout[layout] ~= nil then
		local mask = DungeonLayout[layout].mask
		maskCells(dungeon, mask or {{ 1 }})
	end
end

local function soundRoom(dungeon, r1, c1, r2, c2)
	local cell = dungeon["cell"]
	local hit = {}

	for r = r1, r2 do
		for c = c1, c2 do
			if bcheck(cell[r][c], Flags.BLOCKED) ~= 0 then
				return { ["blocked"] = true }
			end

			if bcheck(cell[r][c], Flags.ROOM) ~= 0 then
				local id = bit.rshift(bit.band(cell[r][c], Flags.ROOM_ID), 6)
				local sId = tostring(id)
				hit[sId] = id + 1
			end
		end
	end

	return hit
end

local function setRoom(a, b)
	b["size"] = b["size"] or a["room_size"]
	local c = RoomSize[b["size"]]
	local d = c["size"] or 2
	local c = c["radix"] or 5
	if b["height"] == nil then
		if b["i"] ~= nil then
			local e = mmax(a["n_i"] - d - b["i"], 0)
			e = mmin(e, c)
			b["height"] = mrandom(e) + d
		else
			b["height"] = mrandom(c) + d
		end
	end
	if b["width"] == nil then
		if b["j"] ~= nil then
			local e = mmax(a["n_j"] - d - b["j"], 0)
			b['width'] = mrandom(e) + d
		else
			b['width'] = mrandom(c) + d
		end
	end
	if b["i"] == nil then
		b["i"] = mrandom(a["n_i"] - b["height"])
	end
	if b["j"] == nil then
		b["j"] = mrandom(a["n_j"] - b["width"])
	end

	return b
end

local function emplaceRoom(a, b)
	if a["n_rooms"] == 999 then return end

	local c = b or {}
	local c = setRoom(a, c)
	local b = c["i"] * 2 + 1
	local d = c["j"] * 2 + 1
	local e = (c["i"] + c["height"]) * 2 - 1
	local g = (c["j"] + c["width"]) * 2 - 1
	if b < 1 or e > a["max_row"] then return end
	if d < 1 or g > a["max_col"] then return end
	local f = soundRoom(a, b, d, e, g)
	if f["blocked"] then return end

	local f = getKeys(f)
	local h = #f
	if h == 0 then
		f = a["n_rooms"] + 1
		a["n_rooms"] = f
	elseif h == 1 then
		if a["complex_rooms"] then
			f = f[1] -- or 1?
			if f ~= c["complex_id"] then return end
		else
			return
		end
	else
		return
	end

	for h = b, e do
		for i = d, g do
			if bcheck(a["cell"][h][i], Flags.ENTRANCE) ~= 0 then
				bclear(a["cell"][h][i], Flags.ESPACE)
			elseif bcheck(a["cell"][h][i], Flags.PERIMETER) ~= 0 then
				bclear(a["cell"][h][i], Flags.PERIMETER)
			end			
			a["cell"][h][i] = bset(a["cell"][h][i], Flags.ROOM, bit.lshift(f, 6))
		end
	end

	local h = (e - b + 1) * 10
	local i = (g - d + 1) * 10
	local c = {
		["id"] = f,
		["size"] = c["size"],
		["row"] = b,
		["col"] = d,
		["north"] = b,
		["south"] = e,
		["west"] = d,
		["east"] = g,
		["height"] = h,
		["width"] = i,
		["door"] = {
			["north"] = {},
			["south"] = {},
			["west"] = {},
			["east"] = {},
		}
	}
	local h = a["room"][f]
	if h ~= nil then
		if h["complex"] ~= nil then 
			table.insert(h["complex"], c)
		else
			complex = {
				["complex"] = { h, c }
			}
			a["room"][f] = complex
		end
	else
		a["room"][f] = c		
	end

	for h = b - 1, e + 1 do
		if bcheck(a["cell"][h][d - 1], Flags.ROOM_ENTRANCE) == 0 then
			a["cell"][h][d - 1] = bset(a["cell"][h][d - 1], Flags.PERIMETER)
		end
		if bcheck(a["cell"][h][g + 1], Flags.ROOM_ENTRANCE) == 0 then
			a["cell"][h][g + 1] = bset(a["cell"][h][g + 1], Flags.PERIMETER)
		end
	end
	for i = d - 1, g + 1 do
		if bcheck(a["cell"][b - 1][i], Flags.ROOM_ENTRANCE) == 0 then
			a["cell"][b - 1][i] = bset(a["cell"][b - 1][i], Flags.PERIMETER)
		end
		if bcheck(a["cell"][e + 1][i], Flags.ROOM_ENTRANCE) == 0 then
			a["cell"][e + 1][i] = bset(a["cell"][e + 1][i], Flags.PERIMETER)
		end
	end
end

local function allocRooms(a, b)
	local a = a
	local c = b or a["room_size"]
	local b = a["n_cols"] * a["n_rows"]
	local d = RoomSize[c]
	local c = d["size"] or 2
	local d = d["radix"] or 5
	local c = c + d + 1
	local c = c * c
	local b = mfloor(b / c) * 2
	
	if (a["room_layout"] == "sparse") then b = mfloor(b / 13) end

	return b
end

local function denseRooms(a)
	for b = 0, a["n_i"] - 1 do
		local c = b * 2 + 1
		for d = 0, a["n_j"] - 1 do
			local e = d * 2 + 1
			if bcheck(a["cell"][c][e], Flags.ROOM) == 0 then
				if not((b == 0 or c == 0) and mrandom(2) > 0) then
					local g = {
						["i"] = b,
						["j"] = d,
					}
					emplaceRoom(a, g)
					if (a["huge_rooms"]) then
						if bcheck(a["cell"][c][e], Flags.ROOM) == 0 then
							g = {
								["i"] = b,
								["j"] = d,
								["size"] = 'medium'
							}
							emplaceRoom(a, g)
						end
					end
				end
			end
		end
	end
end

local function scatterRooms(dungeon)
	local b = allocRooms(dungeon)

	for c = 0, b - 1 do
		emplaceRoom(dungeon)

		if dungeon["huge_rooms"] then
			b = allocRooms(dungeon, "medium")

			for c = 0, b - 1 do
				local d = {
					["size"] = "medium"
				}
				emplaceRoom(dungeon, d)
			end
		end
	end
end

local function emplaceRooms(dungeon)
	local is_huge = RoomSize[dungeon["room_size"]]["huge"]
	local is_complex = RoomLayout[dungeon["room_layout"]]["complex"]

	dungeon["huge_rooms"] = is_huge
	dungeon["complex_rooms"] = is_complex
	dungeon["n_rooms"] = 0
	dungeon["rooms"] = {}

	if dungeon["room_layout"] == "dense" then
		denseRooms(dungeon)
	else
		scatterRooms(dungeon)
	end
end

local function allocOpens(dungeon, room)
	local room_h = (room["south"] - room["north"]) / 2 + 1
	local room_w = (room["east"] - room["west"]) / 2 + 1
	local flumph = mfloor(msqrt(room_w * room_h))
	local n_opens = flumph + mrandom(flumph)

	return n_opens
end

local function checkSill(cell, room, sill_r, sill_c, dir)
	local door_r = sill_r + di[dir]
	local door_c = sill_c + dj[dir]
	local door_cell = cell[door_r][door_c]
	if bcheck(door_cell, Flags.PERIMETER) == 0 then return end
	if bcheck(door_cell, Flags.BLOCK_DOOR) ~= 0 then return end
	local out_r = door_r + di[dir]
	local out_c = door_c + dj[dir]
	local out_cell = cell[out_r][out_c]
	if bcheck(out_cell, Flags.BLOCKED) ~= 0 then return end

	local out_id = tonumber(bit.rshift(bit.band(out_cell, Flags.ROOM_ID), 6))

	if out_id == room["id"] then return end

	return {
		["sill_r"] = sill_r,
		["sill_c"] = sill_c,
		["dir"] = dir,
		["door_r"] = door_r,
		["door_c"] = door_c,
		["out_id"] = out_id,
	}
end

local function doorSills(dungeon, room)
	local cell = dungeon["cell"]
	local list = {}

	if room["north"] >= 3 then
		for c = room["west"], room["east"], 2 do
			local sill = checkSill(cell, room, room["north"], c, "north")
			if sill ~= nil then list[#list + 1] = sill end
		end
	end

	if room["south"] <= dungeon["n_rows"] - 3 then
		for c = room["west"], room["east"], 2 do
			local sill = checkSill(cell, room, room["south"], c, "south")
			if sill ~= nil then list[#list + 1] = sill end
		end
	end

	if room["west"] >= 3 then
		for r = room["north"], room["south"], 2 do
			local sill = checkSill(cell, room, r, room["west"], "west")
			if sill ~= nil then list[#list + 1] = sill end
		end
	end

	if room["east"] <= dungeon["n_cols"] - 3 then
		for r = room["north"], room["south"], 2 do
			local sill = checkSill(cell, room, r, room["east"], "east")			
			if sill ~= nil then list[#list + 1] = sill end
		end
	end

	return shuffle(list)
end

local function openDoor(dungeon, room, sill)
	local cell = dungeon["cell"]

	local door_r = sill["door_r"]
	local door_c = sill["door_c"]

	local open_r = sill["sill_r"]
	local open_c = sill["sill_c"]
	local open_dir = sill["dir"]

	local out_id = sill["out_id"]

    for x = 0, 2 do
    	local r = open_r + di[open_dir] * x
    	local c = open_c + dj[open_dir] * x

    	cell[r][c] = bclear(cell[r][c], Flags.PERIMETER)
    	cell[r][c] = bset(cell[r][c], Flags.ENTRANCE)
    end

    local door_type = getDoorType(dungeon)
    local door = {
    	["row"] = door_r,
    	["col"] = door_c,
    }

    if door_type == Flags.ARCH then
    	cell[door_r][door_c] = bset(cell[door_r][door_c], Flags.ARCH)
    	door["key"] = "arch"
    	door["type"] = "Archway"
    elseif door_type == Flags.DOOR then
    	cell[door_r][door_c] = bset(cell[door_r][door_c], Flags.DOOR)
    	door["key"] = "open"
    	door["type"] = "Unlocked Door"
    	cell[door_r][door_c] = bset(cell[door_r][door_c], bit.lshift(string.byte('o'), 24))
    elseif door_type == Flags.LOCKED then
    	cell[door_r][door_c] = bset(cell[door_r][door_c], Flags.LOCKED)
    	door["key"] = "lock"
    	door["type"] = "Locked Door"
    	cell[door_r][door_c] = bset(cell[door_r][door_c], bit.lshift(string.byte('x'), 24))
    elseif door_type == Flags.TRAPPED then
    	cell[door_r][door_c] = bset(cell[door_r][door_c], Flags.TRAPPED)
    	door["key"] = "trap"
    	door["type"] = "Trapped Door"
    	cell[door_r][door_c] = bset(cell[door_r][door_c], bit.lshift(string.byte('t'), 24))
    elseif door_type == Flags.SECRET then
    	cell[door_r][door_c] = bset(cell[door_r][door_c], Flags.SECRET)
    	door["key"] = "secret"
    	door["type"] = "Secret Door"
    	cell[door_r][door_c] = bset(cell[door_r][door_c], bit.lshift(string.byte('s'), 24))
    elseif door_type == Flags.PORTC then	        	
    	cell[door_r][door_c] = bset(cell[door_r][door_c], Flags.PORTC)
    	door["key"] = "portc"
    	door["type"] = "Portcullis"
    	cell[door_r][door_c] = bset(cell[door_r][door_c], bit.lshift(string.byte('#'), 24))
    end

    if out_id ~= nil then door["out_id"] = out_id end

    table.insert(room["door"][open_dir], door)	
end

local connect = {}

local function openRoom(dungeon, room)
	local list = doorSills(dungeon, room)
	if #list == 0 then return end

	local n_opens = allocOpens(dungeon, room)
	local cell = dungeon["cell"]

	for i = 0, n_opens + 1 do
		if #list == 0 then break end

		local idx = mrandom(#list)
		local sill = table.remove(list, idx)
		local door_r = sill["door_r"]
		local door_c = sill["door_c"]
		local door_cell = cell[door_r][door_c]

		if bcheck(door_cell, Flags.DOORSPACE) == 0 then
			local out_id = sill["out_id"]
			if out_id ~= nil then
				local room_ids = { room["id"], out_id } 			
				table.sort(room_ids)
				local id = table.concat(room_ids, ',')
				if not connect[id] then
					openDoor(dungeon, room, sill)
					connect[id] = true 
				end
			else
				openDoor(dungeon, room, sill)
			end
		end
	end
end

local function fixDoors(dungeon)
	local cell = dungeon["cell"]
	local fixed = {}

	for _, room in ipairs(dungeon["room"]) do
		for dir, _ in pairsByKeys(room["door"]) do
			local shiny = {}

			for _, door in ipairs(room["door"][dir]) do
				local door_r = door["row"]
				local door_c = door["col"]
				local door_cell = cell[door_r][door_c]

				if bcheck(door_cell, Flags.OPENSPACE) == 0 then goto continue end

				local door_id = door_r..'.'..door_c

				if fixed[door_id] ~= nil then
					shiny[#shiny + 1] = door
				else
					if door["out_id"] ~= nil then
						local out_id = door["out_id"]
						out_dir = opposite[dir]

						if dungeon["room"][out_id] == nil then
							dungeon["room"][out_id] = {}
							dungeon["room"][out_id]["door"] = {}
						end

						dungeon["room"][out_id]["door"][out_dir] = door
					end
					shiny[#shiny + 1] = door
					fixed[door_id] = true
				end

				::continue::
			end

			if #shiny > 0 then
				room["door"][dir] = shiny
				concat(dungeon["door"], shiny)
			else
				room["door"][dir] = nil
			end
		end
	end
end

local function checkTunnel(cell, r, c, check)
	local list = check["corridor"]
	if list ~= nil then
		for _, p in ipairs(list) do
			if bcheck(cell[r + p[1]][c + p[2]], Flags.CORRIDOR) == 0 then
				return false
			end
		end
	end

	list = check["walled"]
	if list ~= nil then
		for _, p in ipairs(list) do
			if bcheck(cell[r + p[1]][c + p[2]], Flags.OPENSPACE) ~= 0 then
				return false
			end			
		end
	end

	return true
end

local function emptyBlocks(dungeon)
	local cell = dungeon["cell"]

	for r = 0, dungeon["n_rows"] do
		for c = 0, dungeon["n_cols"] do
			-- clear all blocked cells, nothing to see here ...
			if bcheck(cell[r][c], Flags.BLOCKED) ~= 0 then
				cell[r][c] = Flags.NOTHING
			end

			-- inside rooms, remove all corridors
			if bcheck(cell[r][c], Flags.OPENSPACE) == Flags.OPENSPACE then
				cell[r][c] = bclear(cell[r][c], Flags.CORRIDOR)
			end

			-- remove all perimeters around rooms
			if bcheck(cell[r][c], Flags.PERIMETER) ~= 0 then
				cell[r][c] = bclear(cell[r][c], Flags.PERIMETER)
			end

			-- only tag door cells if connected to corridor
			if (bcheck(cell[r][c], Flags.DOORSPACE) ~= 0 and 
				bcheck(cell[r][c], Flags.CORRIDOR) == 0) then
				cell[r][c] = bclear(cell[r][c], Flags.DOORSPACE)
			end
		end
	end
end

local function collapse(dungeon, r, c, xc)
	local cell = dungeon["cell"]

	if bcheck(cell[r][c], Flags.OPENSPACE) == 0 then return end

	for _, dir in pairs(getKeys(xc)) do
		if checkTunnel(cell, r, c, xc[dir]) then
			for _, p in ipairs(xc[dir]["close"]) do
				cell[r + p[1]][c + p[2]] = Flags.NOTHING
			end

			local p = xc[dir]["open"]
			if p ~= nil then
				cell[r + p[1]][c + p[2]] = bset(cell[r + p[1]][c + p[2]], Flags.CORRIDOR)
			end

			p = xc[dir]["recurse"]
			if p ~= nil then
				collapse(dungeon, r + p[1], c + p[2], xc)
			end
		end
	end
end

local function collapseTunnels(dungeon, percentage, xc)
	if percentage == 0 then return end

	local all = percentage == 100
	local cell = dungeon["cell"]

	for i = 0, dungeon["n_i"] - 1 do
		local r = (i * 2) + 1
		for j = 0, dungeon["n_j"] - 1 do
			local c = (j * 2) + 1

			if bcheck(cell[r][c], Flags.OPENSPACE) == 0 then goto continue end
			if bcheck(cell[r][c], Flags.STAIRS) ~= 0 then goto continue end
			if all or mrandom(100) < percentage then
				collapse(dungeon, r, c, xc)
			end

			::continue::
		end
	end
end

local function removeDeadends(dungeon, percentage)
	dungeon["remove_pct"] = percentage

	collapseTunnels(dungeon, percentage, close_end)    
end

local function closeArcs(dungeon)
	collapseTunnels(dungeon, dungeon["close_arcs"], close_arcs)
end

local function cleanDungeon(dungeon)	
	local percentage = RemoveDeadends[dungeon["remove_deadends"]]

	if percentage > 0 then
		removeDeadends(dungeon, percentage)

		--[[
		-- TODO: seems buggy with stair rendering - also not sure what this adds

		if dungeon["corridor_layout"] == "errant" then
			dungeon["close_arcs"] = dungeon["remove_pct"]
		elseif dungeon["corridor_layout"] == "straight" then
			dungeon["close_arcs"] = dungeon["remove_pct"]
		end
	end

	if dungeon["close_arcs"] ~= nil then
		closeArcs(dungeon)
		--]]
	end

	fixDoors(dungeon)
	emptyBlocks(dungeon)
end

local function openRooms(dungeon)
	connect = {}

	for id = 1, dungeon["n_rooms"] do
		openRoom(dungeon, dungeon["room"][id])
	end
end

--[[
    var b;
    for (b = 1; b <= a.n_rooms; b++) {
        var c = a.room[b],
            d = c.id.toString(),
            e = d.length,
            g = Math.floor((c.north + c.south) / 2);
        c = Math.floor((c.west + c.east - e) / 2) + 1;
        var f;
        for (f = 0; f < e; f++) a.cell[g][c + f] |= d.charCodeAt(f) << 24
    }
    return a
]]

local function labelRooms(dungeon)
	local cell = dungeon["cell"]

	for id = 1, dungeon["n_rooms"] do
		local room = dungeon["room"][id]
		local label = room["id"]
		local len = string.len(label)
		local label_r = mfloor((room["north"] + room["south"]) / 2)
		local label_c = mfloor((room["west"] + room["east"] - len) / 2) + 1

		for c = 0, len - 1 do
			local char = string.sub(label, c + 1)
			local mask = bit.lshift(string.byte(char), 24)
			cell[label_r][label_c + c] = bset(cell[label_r][label_c + c], mask)
		end
	end
end

local function tunnelDirs(dungeon, last_dir)
	-- TODO: what does it matter if we use sorted table dj_dirs while
	-- afterwards shuffling as in original code?
	local keys = getKeys(dj)
	local dirs = shuffle(keys)
	local p = dungeon["straight_pct"]

	if last_dir ~= nil and p ~= nil then
		if mrandom(100) < p then
			table.insert(dirs, 1, last_dir)
		end
	end

	return dirs
end

local function delveTunnel(dungeon, this_r, this_c, next_r, next_c)
	local cell = dungeon["cell"]

	local tbl_r, tbl_c = { this_r, next_r }, { this_c, next_c }
	
	table.sort(tbl_r)
	local r1, r2 = unpack(tbl_r)

	table.sort(tbl_c)
	local c1, c2 = unpack(tbl_c)

	for r = r1, r2 do
		for c = c1, c2 do
			cell[r][c] = bclear(cell[r][c], Flags.ENTRANCE)
			cell[r][c] = bset(cell[r][c], Flags.CORRIDOR)
		end
	end

	return true
end

local function soundTunnel(dungeon, mid_r, mid_c, next_r, next_c)
	if next_r < 0 or next_r > dungeon["n_rows"] then return false end
	if next_c < 0 or next_c > dungeon["n_cols"] then return false end

	local cell = dungeon["cell"]
	local tbl_r, tbl_c = { mid_r, next_r }, { mid_c, next_c }

	table.sort(tbl_r)
	local r1, r2 = unpack(tbl_r)

	table.sort(tbl_c)
	local c1, c2 = unpack(tbl_c)

	for r = r1, r2 do
		for c = c1, c2 do
			if bcheck(cell[r][c], Flags.BLOCK_CORR) ~= 0 then return false end
		end
	end	

	return true
end

local function openTunnel(dungeon, i, j, dir)
	local this_r = (i * 2) + 1
	local this_c = (j * 2) + 1
	local next_r = ((i + di[dir]) * 2) + 1
	local next_c = ((j + dj[dir]) * 2) + 1
	local mid_r = (this_r + next_r) / 2
	local mid_c = (this_c + next_c) / 2

	if soundTunnel(dungeon, mid_r, mid_c, next_r, next_c) then
		return delveTunnel(dungeon, this_r, this_c, next_r, next_c)
	else
		return false
	end
end

local function tunnel(dungeon, i, j, last_dir)
	local dirs = tunnelDirs(dungeon, last_dir)

	for _, dir in ipairs(dirs) do
		if openTunnel(dungeon, i, j, dir) then
			local next_i = i + di[dir]
			local next_j = j + dj[dir]

			tunnel(dungeon, next_i, next_j, dir)
		end
	end
end

local function corridors(dungeon)
	local cell = dungeon["cell"]

	dungeon["straight_pct"] = CorridorLayout[dungeon["corridor_layout"]]

	for i = 1, dungeon["n_i"] - 1 do
		local r = i * 2 + 1
		for j = 1, dungeon["n_j"] - 1 do
			local c = j * 2 + 1

			if bcheck(cell[r][c], Flags.CORRIDOR) ~= 0 then goto continue end

			tunnel(dungeon, i, j, last_dir)

			::continue::
		end
	end
end

local function stairEnds(dungeon)
	local cell = dungeon["cell"]
	local list = {}

	for i = 0, dungeon["n_i"] - 1 do
		local r = (i * 2) + 1
		for j = 0, dungeon["n_j"] - 1 do
			local c = (j * 2) + 1

			if bcheck(cell[r][c], Flags.CORRIDOR) == 0 then goto continue end
			if bcheck(cell[r][c], Flags.STAIRS) ~= 0 then goto continue end

			for _, dir in ipairs(getKeys(stair_end)) do
				if checkTunnel(cell, r, c, stair_end[dir]) then
					local s_end = { ["row"] = r, ["col"] = c, ["dir"] = dir }
					local n = stair_end[dir]["next"]
					s_end["next_row"] = s_end["row"] + n[1]
					s_end["next_col"] = s_end["col"] + n[2]

					table.insert(list, s_end)
					break
				end				
			end

			::continue::
		end
	end

	return list
end

local function emplaceStairs(dungeon)
	local n = AddStairs[dungeon["add_stairs"]]

	if n == 0 then return end

	if n == mhuge then
		n = dungeon["n_cols"] * dungeon["n_rows"]
		n = 2 + mrandom(n / 1e3)
	end

	local list = stairEnds(dungeon)
	local cell = dungeon["cell"]

	shuffle(list)

	for i = 0, n - 1 do
		if #list == 0 then return end

		local stair = table.remove(list)

		local r, next_r = stair["row"], stair["next_row"]
		local c, next_c = stair["col"], stair["next_col"]
		local s_type = i < 2 and (i + 1) or mrandom(2)

		if s_type == 1 then
			cell[r][c] = bset(cell[r][c], Flags.STAIR_DN)
			cell[r][c] = bset(cell[r][c], bit.lshift(string.byte("d"), 24))
			stair["key"] = "down"
		else
			cell[r][c] = bset(cell[r][c], Flags.STAIR_UP)
			cell[r][c] = bset(cell[r][c], bit.lshift(string.byte("u"), 24))
			stair["key"] = "up"
		end

		table.insert(dungeon["stair"], stair)
	end
end

local function generate(options)
	love.math.setRandomSeed(options["seed"])

	local dungeon = Dungeon(options)

	applyLayout(dungeon)
	emplaceRooms(dungeon)
	openRooms(dungeon)
	labelRooms(dungeon)
	corridors(dungeon)
	emplaceStairs(dungeon)
	cleanDungeon(dungeon)

	--[[
	print('\ndungeon:')
	for k, v in pairs(dungeon) do
		print(' ' .. k, v)
	end
	--]]

	return dungeon
end

return setmetatable({
	generate = generate,
}, {})