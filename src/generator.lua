require 'src/flags'
BitMask = require 'src/bitmask'

local bset, bclear, bcheck = BitMask.set, BitMask.clear, BitMask.check
local mfloor, mrandom, msqrt, pow = math.floor, math.random, math.sqrt, math.pow
local mmax, mmin, mabs = math.max, math.min, math.abs

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
};

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
};

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

--[[ TODO: 
	* Improve implementation, all layout names should be public
	or perhaps just forward layout tables instead, so users 
	can provide custom layouts
	* Donjon's JavaScript implementation adds additional options 
	for layouts and aspect ratios
--]]
local dungeon_layout = {
	["Box"] = { 
		[0] = 
			{ [0] = 1, 1, 1 }, 
			{ [0] = 1, 1, 1 },
			{ [0] = 1, 1, 1 },
	},
	["Cross"] = { 
		[0] = 
			{ [0] = 0, 1, 0 }, 
			{ [0] = 1, 1, 1 },
			{ [0] = 0, 1, 0 },
	},
	["Keep"] = {
		[0] =
			{ [0] = 1, 1, 0, 0, 1, 1 },
			{ [0] = 1, 1, 1, 1, 1, 1 },
			{ [0] = 0, 1, 1, 1, 1, 0 },
			{ [0] = 0, 1, 1, 1, 1, 0 },
			{ [0] = 1, 1, 1, 1, 1, 1 },
			{ [0] = 1, 1, 0, 0, 1, 1 },
	},
	["Dagger"] = {
		[0] = 
			{ [0] = 0, 1, 0 }, 
			{ [0] = 1, 1, 1 },
			{ [0] = 0, 1, 0 },
			{ [0] = 0, 1, 0 },
	},
	["Round"] = {},
	["Saltire"] = {},
	["Hexagon"] = {}
}

local corridor_layout = {
	["Labyrinth"] 	= 0,
	["Bent"] 		= 50,
	["Straight"] 	= 100,	
}

local function getDoorType()
	local i = mfloor(mrandom(110))

	if i < 15 then
		return Flags.ARCH
	elseif i < 60 then
		return Flags.DOOR
	elseif i < 75 then
		return Flags.LOCKED
	elseif i < 90 then
		return Flags.TRAPPED
	elseif i < 100 then
		return Flags.SECRET
	else
		return Flags.PORTC
	end
end

local function maskCells(dungeon, mask)
	local r_x = #mask * 1.0 / (dungeon["n_rows"])
	local c_x = #mask[0] * 1.0 / (dungeon["n_cols"])
	local cell = dungeon["cell"]

	for r = 0, dungeon["n_rows"] do
		for c = 0, dungeon["n_cols"] do
			cell[r][c] = (
				mask[mfloor(r * r_x + 0.5)][mfloor(c * c_x + 0.5)] == 1 
				and Flags.NOTHING 
				or Flags.BLOCKED)
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

local function initCells(dungeon, mask)
	dungeon["cell"] = {}

	for r = 0, dungeon["n_rows"] do
		dungeon["cell"][r] = {}
		for c = 0, dungeon["n_cols"] do
			dungeon["cell"][r][c] = Flags.NOTHING
		end
	end

	if mask == "Round" then
		roundMask(dungeon)
	elseif mask == "Saltire" then
		saltireMask(dungeon)
	elseif mask == "Hexagon" then
		hexagonMask(dungeon)
	elseif dungeon_layout[mask] ~= nil then
		maskCells(dungeon, dungeon_layout[mask])		
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

local function setRoom(dungeon, proto)
	local base = dungeon["room_base"]
	local radix = dungeon["room_radix"]

	if proto["height"] == nil then
		if proto["i"] ~= nil then
			local a = dungeon["n_i"] - base - proto["i"]
			a = mmath.max(a, 0)
			local r = mmin(a, radix)
			proto["height"] = mfloor(mrandom(r) + base)
		else			
			proto["height"] = mfloor(mrandom(radix)) + base
		end
	end

	if proto["width"] == nil then
		if proto["j"] ~= nil then
			local a = mmax(dungeon["n_j"] - base - proto["j"], 0)
			local r = mmin(a, radix)
			proto["width"] = mfloor(mrandom(r) + base)
		else
			proto["width"] = mfloor(mrandom(radix)) + base
		end
	end

	if proto["i"] == nil then
		proto["i"] = mfloor(mrandom(dungeon["n_i"] - proto["height"]))
	end

	if proto["j"] == nil then
		proto["j"] = mfloor(mrandom(dungeon["n_j"] - proto["width"]))
	end
end

local function emplaceRoom(dungeon, proto)
	if dungeon["n_rooms"] == 999 then return end

	local cell = dungeon["cell"]
	local proto = proto or {}

	setRoom(dungeon, proto)

	local r1 = proto["i"] * 2 + 1
	local c1 = proto["j"] * 2 + 1
	local r2 = (proto["i"] + proto["height"]) * 2 - 1
	local c2 = (proto["j"] + proto["width"]) * 2 - 1

	if r1 < 1 or r2 > dungeon["max_row"] then return end
	if c1 < 1 or c2 > dungeon["max_col"] then return end

	local hit = soundRoom(dungeon, r1, c1, r2, c2)

	if hit["blocked"] == true then return end

	local hit_list = getKeys(hit)
	local room_id = nil

	if #hit_list == 0 then
		room_id = dungeon["n_rooms"] + 1
		dungeon["n_rooms"] = room_id
	else
		return
	end

	dungeon["last_room_id"] = room_id
	
	for r = r1, r2 do
		for c = c1, c2 do
			if bcheck(cell[r][c], Flags.ENTRANCE) ~= 0 then
				cell[r][c] = bclear(cell[r][c], bit.bnot(Flags.ESPACE))
			elseif bcheck(cell[r][c], Flags.PERIMETER) ~= 0 then
				cell[r][c] = bclear(cell[r][c], Flags.PERIMETER)
			end
			cell[r][c] = bset(cell[r][c], Flags.ROOM, bit.lshift(room_id, 6))
		end
	end

	local height = ((r2 - r1) + 1) * 10
	local width = ((c2 - c1) + 1) * 10

	local room_data = {
		["id"] = room_id, 
		["row"] = r1, ["col"] = c1,
		["north"] = r1, ["south"] = r2, ["west"] = c1, ["east"] = c2,
		["height"] = height, ["width"] = width, 
		["area"] = height * width,
		["door"] = {
			["north"] = {},
			["east"] = {},
			["west"] = {},
			["south"] = {},
		},
	}
	dungeon["room"][room_id] = room_data

	for r = r1 - 1, r2 + 1 do
		if bcheck(cell[r][c1 - 1], Flags.ROOM_ENTRANCE) == 0 then
			cell[r][c1 - 1] = bset(cell[r][c1 - 1], Flags.PERIMETER)
		end
		if bcheck(cell[r][c1 + 1], Flags.ROOM_ENTRANCE) == 0 then
			cell[r][c2 + 1] = bset(cell[r][c2 + 1], Flags.PERIMETER)
		end
	end

	for c = c1 - 1, c2 + 1 do
		if bcheck(cell[r1 - 1][c], Flags.ROOM_ENTRANCE) == 0 then
			cell[r1 - 1][c] = bset(cell[r1 - 1][c], Flags.PERIMETER)
		end
		if bcheck(cell[r2 + 1][c], Flags.ROOM_ENTRANCE) == 0 then
			cell[r2 + 1][c] = bset(cell[r2 + 1][c], Flags.PERIMETER)
		end		
	end
end

local function allocRooms(dungeon, room_max)
	local dungeon_area = dungeon["n_cols"] * dungeon["n_rows"]
	local room_area = room_max * room_max
	local n_rooms = mfloor(dungeon_area / room_area)

	return n_rooms
end

local function packRooms(dungeon)
	local cell = dungeon["cell"]

	for i = 0, dungeon["n_i"] - 1 do
		local r = i * 2 + 1
		for j = 0, dungeon["n_j"] - 1 do
			local c = j * 2 + 1

			local has_room = bcheck(cell[r][c], Flags.ROOM) ~= 0
			local is_ignore = (i == 0 or j == 0) and mrandom(0, 1) == 1

			if not has_room and not is_ignore then
				local proto = { 
					["i"] = i, 
					["j"] = j 
				}
				emplaceRoom(dungeon, proto)
			end
		end
	end
end

local function scatterRooms(dungeon, room_max)
	local nRooms = allocRooms(dungeon, room_max)

	for i = 0, nRooms - 1 do
		emplaceRoom(dungeon)
	end
end

local function emplaceRooms(dungeon, roomLayout, room_max)
	if roomLayout == 'Packed' then
		packRooms(dungeon, room_max)
	else 
		scatterRooms(dungeon, room_max)
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

	local out_id = nil

	if bcheck(out_cell, Flags.ROOM) ~= 0 then
		out_id = bit.rshift(bit.band(out_cell, Flags.ROOM_ID), 6)
		if out_id == room["id"] then return end
	end

	return {
		["sill_r"] = sill_r,
		["sill_c"] = sill_c,
		["dir"] = dir,
		["door_r"] = door_r,
		["door_c"] = door_c,
		["out_id"] = tonumber(out_id),
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

local function openRoom(dungeon, room)
	local connect = {}

	local list = doorSills(dungeon, room)
	if #list == 0 then return end

	local n_opens = allocOpens(dungeon, room)
	local cell = dungeon["cell"]

	for i = 0, n_opens do
		if #list == 0 then break end

		local idx = mrandom(#list)
		local sill = table.remove(list, idx)
		local door_r = sill["door_r"]
		local door_c = sill["door_c"]
		local door_cell = cell[door_r][door_c]

		if bcheck(door_cell, Flags.DOORSPACE) ~= 0 then 
			goto continue
		end

		local out_id = sill["out_id"]
		if out_id ~= nil then
			local room_ids = { room["id"], out_id } 			
			table.sort(room_ids, function(id1, id2) return id1 < id2 end)
			local id = table.concat(room_ids, ',')
			
			--[[
				TODO: seems Donjon's JavaScript and Perl implementations differ 
				here - the Perl implementation restarts the loop on setting 
				connection and the JavaScript implementation continues the loop.
				I follow the JavaScript implementation here, otherwise I feel 1
				door is always 'missing'.
			--]]
			if not connect[id] then connect[id] = true end

			goto continue
		end

		local open_r = sill["sill_r"]
		local open_c = sill["sill_c"]
		local open_dir = sill["dir"]
	
        for x = 0, 2 do
        	local r = open_r + di[open_dir] * x
        	local c = open_c + dj[open_dir] * x

        	cell[r][c] = bclear(cell[r][c], Flags.PERIMETER)
        	cell[r][c] = bset(cell[r][c], Flags.ENTRANCE)
        end

        local door_type = getDoorType()
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

        ::continue::
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

local function collapseTunnels(dungeon, p, xc)
	if p == 0 then return end

	local all = p == 100
	local cell = dungeon["cell"]

	for i = 0, dungeon["n_i"] - 1 do
		local r = (i * 2) + 1
		for j = 0, dungeon["n_j"] - 1 do
			local c = (j * 2) + 1

			if bcheck(cell[r][c], Flags.OPENSPACE) == 0 then goto continue end
			if bcheck(cell[r][c], Flags.STAIRS) ~= 0 then goto continue end
			if all or mrandom(100) < p then
				collapse(dungeon, r, c, xc)
			end

			::continue::
		end
	end
end

local function removeDeadends(dungeon, percentage)
	collapseTunnels(dungeon, percentage, close_end)    
end

local function cleanDungeon(dungeon, remove_deadends)
	if remove_deadends > 0 then
		removeDeadends(dungeon, remove_deadends)
	end

	fixDoors(dungeon)
	emptyBlocks(dungeon)
end

local function openRooms(dungeon)
	for id = 1, dungeon["n_rooms"] do
		openRoom(dungeon, dungeon["room"][id])
	end
end

local function labelRooms(dungeon)
	local cell = dungeon["cell"]

	for id = 1, dungeon["n_rooms"] do
		local room = dungeon["room"][id]
		local label = room["id"]
		local len = string.len(label)
		local label_r = mfloor((room["north"] + room["south"]) / 2)
		local label_c = mfloor((room["west"] + room["east"] - len) / 2) + 1

		for c = 0, len - 1 do
			local char = string.sub(label, c, 1)
			local mask = bit.lshift(string.byte(char), 24)
			cell[label_r][label_c + c] = bset(cell[label_r][label_c + c], mask)
		end
	end
end

local function tunnelDirs(dungeon, layout, last_dir)
	local p = corridor_layout[layout]

	-- TODO: what does it matter if we use sorted table dj_dirs while
	-- afterwards shuffling as in original code?
	local keys = getKeys(dj)
	local dirs = shuffle(keys)

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

local function tunnel(dungeon, layout, i, j, last_dir)
	local dirs = tunnelDirs(dungeon, layout, last_dir)

	for _, dir in ipairs(dirs) do
		if openTunnel(dungeon, i, j, dir) then
			local next_i = i + di[dir]
			local next_j = j + dj[dir]

			tunnel(dungeon, layout, next_i, next_j, dir)
		end
	end
end

local function corridors(dungeon, layout)
	local cell = dungeon["cell"]

	for i = 1, dungeon["n_i"] - 1 do
		local r = i * 2 + 1
		for j = 1, dungeon["n_j"] - 1 do
			local c = j * 2 + 1

			if bcheck(cell[r][c], Flags.CORRIDOR) ~= 0 then goto continue end

			tunnel(dungeon, layout, i, j, last_dir)

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
					local s_end = { ["row"] = r, ["col"] = c }
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

local function emplaceStairs(dungeon, n)
	if n <= 0 then return end

	local list = stairEnds(dungeon)

	local cell = dungeon["cell"]

	shuffle(list)

	for i = 0, n - 1 do
		if #list == 0 then return end

		local stair = table.remove(list)

		local r = stair["row"]
		local c = stair["col"]
		local s_type = i < 2 and i or mrandom(2)

		if s_type == 0 then
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

	local dungeon_size = dungeon_size[options["dungeon_size"]]
	print(s)
	--local n_i = mfloor(s * e / b)
	--local n_j = Math.floor(d * e / b);
    local n_i, n_j = dungeon_size, dungeon_size

	local dungeon = {}

	dungeon["n_i"] = n_i
	dungeon["n_j"] = n_j
	dungeon["n_rows"] = n_i * 2
	dungeon["n_cols"] = n_j * 2
	dungeon["max_row"] = dungeon["n_rows"] - 1
	dungeon["max_col"] = dungeon["n_cols"] - 1
	dungeon["n_rooms"] = 0
	dungeon["room"] = {}
	dungeon["door"] = {}
	dungeon["stair"] = {}

	-- TODO: perhaps ugly to copy
	dungeon["cell_size"] = options["cell_size"]

	local max = options["room_max"]
	local min = options["room_min"]
	dungeon["room_base"] = mfloor((min + 1) / 2)
	dungeon["room_radix"] = mfloor((max - min) / 2 + 1)

	print('\ndungeon config:')
	for k, v in pairs(dungeon) do
		print(' ' .. k, v)
	end

	initCells(dungeon, options["dungeon_layout"])
	emplaceRooms(dungeon, options["room_layout"], options["room_max"])
	openRooms(dungeon)
	labelRooms(dungeon)
	corridors(dungeon, options["corridor_layout"])
	emplaceStairs(dungeon, options["add_stairs"])
	cleanDungeon(dungeon, options["remove_deadends"])

	return dungeon
end

return setmetatable({
	generate = generate,
}, {})