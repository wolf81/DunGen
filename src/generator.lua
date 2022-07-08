require 'src.cell'
require 'src.direction'
require 'src.close_arc'
require 'src.close_end'
require 'src.stair_end'
require 'src.config'

local Dungeon = require 'src.dungeon'

local mfloor, mrandom, msqrt, mpow = math.floor, math.random, math.sqrt, math.pow
local mmax, mmin, mabs, mhuge = math.max, math.min, math.abs, math.huge

local function getDoorType(dungeon)
	local doorTypes = Doors[dungeon.doors]
	local max = doorTypes[#doorTypes][1]

	local value = mfloor(mrandom(max))
	local door = Flag.ARCH

	for _, doorType in ipairs(doorTypes) do
		if doorType[1] >= value then break end
		door = doorType[2]
	end

	return door
end

local function maskCells(dungeon, mask)
	local r_x = #mask * 1.0 / (dungeon.n_rows)
	local c_x = #mask[1] * 1.0 / (dungeon.n_cols)
	local cell = dungeon.cell

	for r = 0, dungeon.n_rows - 1 do
		for c = 0, dungeon.n_cols - 1 do
			local y = mfloor(r * r_x + 1.0)
			local x = mfloor(c * c_x + 1.0)
			cell[r][c] = (mask[y][x] == 1 and Flag.NOTHING or Flag.BLOCKED)
		end
	end
end

local function saltireMask(dungeon)
	local cell = dungeon.cell

	local i_max = mfloor(dungeon.n_rows / 4)
	for i = 0, i_max - 1 do
		local j = i + i_max
		local j_max = dungeon.n_cols - j

		for j = j, j_max do
			cell[i][j] = Flag.BLOCKED
			cell[dungeon.n_rows - i][j] = Flag.BLOCKED
			cell[j][i] = Flag.BLOCKED
			cell[j][dungeon.n_cols - i] = Flag.BLOCKED
		end
	end
end

local function hexagonMask(dungeon)
	local cell = dungeon.cell

	local r_half = dungeon.n_rows / 2
	for r = 0, dungeon.n_rows do
		local c_min = mfloor(mabs(r - r_half) * 0.57735)
		local c_max = dungeon.n_cols - c_min

		for c = 0, dungeon.n_cols do
			if c < c_min or c > c_max then
				cell[r][c] = Flag.BLOCKED
			end
		end
	end
end

local function roundMask(dungeon)
	local mid_r = mfloor(dungeon.n_rows / 2)
	local mid_c = mfloor(dungeon.n_cols / 2)
	local cell = dungeon.cell

	for r = 0, dungeon.n_rows do
		for c = 0, dungeon.n_cols do
			local d = msqrt(
				mpow((r - mid_r), 2) + 
				mpow((c - mid_c), 2)
            )
			cell[r][c] = d > mid_c and Flag.BLOCKED or Flag.NOTHING
		end
	end
end

local function applyLayout(dungeon)
	local layout = dungeon.dungeon_layout
	if layout == 'round' then
		roundMask(dungeon)
	elseif layout == 'saltire' then
		saltireMask(dungeon)
	elseif layout == 'hexagon' then
		hexagonMask(dungeon)
	elseif DungeonLayout[layout] ~= nil then
		local mask = DungeonLayout[layout].mask
		maskCells(dungeon, mask or {{ Flag.BLOCKED }})
	end
end

local function soundRoom(dungeon, r1, c1, r2, c2)
	local cell = dungeon.cell
	local hit = {}

	for r = r1, r2 do
		for c = c1, c2 do
			if bit.band(cell[r][c], Flag.BLOCKED) == Flag.BLOCKED then
				return { blocked = true }
			end

			if bit.band(cell[r][c], Flag.ROOM) == Flag.ROOM then
				local id = bit.rshift(bit.band(cell[r][c], Flag.ROOM_ID), 6)
				local sId = tostring(id)
				hit[sId] = id + 1
			end
		end
	end

	return hit
end

local function setRoom(dungeon, b)
	b.size = b.size or dungeon.room_size
	local c = RoomSize[b.size]
	local d = c.size or 2
	local c = c.radix or 5
	if b.height == nil then
		if b.i ~= nil then
			local e = mmax(dungeon.n_i - d - b.i, 0)
			e = mmin(e, c)
			b.height = mrandom(e) + d
		else
			b.height = mrandom(c) + d
		end
	end
	if b.width == nil then
		if b.j ~= nil then
			local e = mmax(dungeon.n_j - d - b.j, 0)
			b['width'] = mrandom(e) + d
		else
			b['width'] = mrandom(c) + d
		end
	end
	if b.i == nil then
		b.i = mrandom(dungeon.n_i - b.height)
	end
	if b.j == nil then
		b.j = mrandom(dungeon.n_j - b.width)
	end

	return b
end

local function emplaceRoom(dungeon, b)
	if dungeon.n_rooms == 999 then return end

	local c = b or {}
	local c = setRoom(dungeon, c)
	local b = c.i * 2 + 1
	local d = c.j * 2 + 1
	local e = (c.i + c.height) * 2 - 1
	local g = (c.j + c.width) * 2 - 1
	if b < 1 or e > dungeon.max_row then return end
	if d < 1 or g > dungeon.max_col then return end
	local f = soundRoom(dungeon, b, d, e, g)
	if f.blocked then return end

	local f = getKeys(f)
	local h = #f
	if h == 0 then
		f = dungeon.n_rooms + 1
		dungeon.n_rooms = f
	elseif h == 1 then
		if dungeon.complex_rooms then
			f = f[1] -- or 1?
			if f ~= c.complex_id then return end
		else
			return
		end
	else
		return
	end

	for h = b, e do
		for i = d, g do            
            local cell = dungeon.cell[h][i]
			if bit.band(cell, Flag.ENTRANCE) == Flag.ENTRANCE then
				cell = bit.band(cell, bit.bnot(Flag.ESPACE))
			elseif bit.band(cell, Flag.PERIMETER) == Flag.PERIMETER then
                cell = bit.band(cell, bit.bnot(Flag.PERIMETER))
			end			

            dungeon.cell[h][i] = bit.bor(cell, bit.bor(Flag.ROOM, bit.lshift(f, 6)))
		end
	end

	local h = (e - b + 1) * 10
	local i = (g - d + 1) * 10
	local c = {
		id = f,
		size = c.size,
		row = b,
		col = d,
		north = b,
		south = e,
		west = d,
		east = g,
		height = h,
		width = i,
		door = {
			north = {},
			south = {},
			west = {},
			east = {},
		}
	}
	local h = dungeon.room[f]
	if h ~= nil then
		if h.complex ~= nil then 
			table.insert(h.complex, c)
		else
			complex = {
				complex = { h, c }
			}
			dungeon.room[f] = complex
		end
	else
		dungeon.room[f] = c		
	end

	for h = b - 1, e + 1 do
		if bit.band(dungeon.cell[h][d - 1], Mask.ROOM_ENTRANCE) == 0 then
			dungeon.cell[h][d - 1] = bit.bor(dungeon.cell[h][d - 1], Flag.PERIMETER)
		end
		if bit.band(dungeon.cell[h][g + 1], Mask.ROOM_ENTRANCE) == 0 then
			dungeon.cell[h][g + 1] = bit.bor(dungeon.cell[h][g + 1], Flag.PERIMETER)
		end
	end
	for i = d - 1, g + 1 do
		if bit.band(dungeon.cell[b - 1][i], Mask.ROOM_ENTRANCE) == 0 then
			dungeon.cell[b - 1][i] = bit.bor(dungeon.cell[b - 1][i], Flag.PERIMETER)
		end
		if bit.band(dungeon.cell[e + 1][i], Mask.ROOM_ENTRANCE) == 0 then
			dungeon.cell[e + 1][i] = bit.bor(dungeon.cell[e + 1][i], Flag.PERIMETER)
		end
	end
end

local function allocRooms(dungeon, b)
	local c = b or dungeon.room_size
	local b = dungeon.n_cols * dungeon.n_rows
	local d = RoomSize[c]
	local c = d.size or 2
	local d = d.radix or 5
	local c = c + d + 1
	local c = c * c
	local b = mfloor(b / c) * 2
	
	if (dungeon.room_layout == 'sparse') then b = mfloor(b / 13) end

	return b
end

local function denseRooms(dungeon)
	for b = 0, dungeon.n_i - 1 do
		local row = b * 2 + 1
		for d = 0, dungeon.n_j - 1 do
			local col = d * 2 + 1
			if bit.band(dungeon.cell[row][col], Flag.ROOM) == 0 then
				if not((b == 0 or c == 0) and mrandom(2) > 0) then
					local g = {
						i = b,
						j = d,
					}
					emplaceRoom(dungeon, g)
					if (dungeon.huge_rooms) then
						if bit.band(dungeon.cell[row][col], Flag.ROOM) == 0 then
							g = {
								i = b,
								j = d,
								size = 'medium'
							}
							emplaceRoom(dungeon, g)
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

		if dungeon.huge_rooms then
			b = allocRooms(dungeon, 'medium')

			for c = 0, b - 1 do
				local d = {
					size = 'medium'
				}
				emplaceRoom(dungeon, d)
			end
		end
	end
end

local function emplaceRooms(dungeon)
	local is_huge = RoomSize[dungeon.room_size].huge
	local is_complex = RoomLayout[dungeon.room_layout].complex

	dungeon.huge_rooms = is_huge
	dungeon.complex_rooms = is_complex
	dungeon.n_rooms = 0
	dungeon.rooms = {}

	if dungeon.room_layout == 'dense' then
		denseRooms(dungeon)
	else
		scatterRooms(dungeon)
	end
end

local function allocOpens(dungeon, room)
	local room_h = (room.south - room.north) / 2 + 1
	local room_w = (room.east - room.west) / 2 + 1
	local flumph = mfloor(msqrt(room_w * room_h))
	local n_opens = flumph + mrandom(flumph)

	return n_opens
end

local function checkSill(cell, room, sill_r, sill_c, dir)
    local di, dj = unpack(Direction.cardinal[dir])
	local door_r = sill_r + di
	local door_c = sill_c + dj
	local door_cell = cell[door_r][door_c]
	if bit.band(door_cell, Flag.PERIMETER) == 0 then return end
	if bit.band(door_cell, Mask.BLOCK_DOOR) ~= 0 then return end
	local out_r = door_r + di
	local out_c = door_c + dj
	local out_cell = cell[out_r][out_c]
	if bit.band(out_cell, Flag.BLOCKED) == Flag.BLOCKED then return end

	local out_id = tonumber(bit.rshift(bit.band(out_cell, Flag.ROOM_ID), 6))

	if out_id == room.id then return end

	return {
		sill_r = sill_r,
		sill_c = sill_c,
		dir = dir,
		door_r = door_r,
		door_c = door_c,
		out_id = out_id,
	}
end

local function doorSills(dungeon, room)
	local cell = dungeon.cell
	local list = {}

	if room.north >= 3 then
		for c = room.west, room.east, 2 do
			local sill = checkSill(cell, room, room.north, c, 'north')
			if sill ~= nil then list[#list + 1] = sill end
		end
	end

	if room.south <= dungeon.n_rows - 3 then
		for c = room.west, room.east, 2 do
			local sill = checkSill(cell, room, room.south, c, 'south')
			if sill ~= nil then list[#list + 1] = sill end
		end
	end

	if room.west >= 3 then
		for r = room.north, room.south, 2 do
			local sill = checkSill(cell, room, r, room.west, 'west')
			if sill ~= nil then list[#list + 1] = sill end
		end
	end

	if room.east <= dungeon.n_cols - 3 then
		for r = room.north, room.south, 2 do
			local sill = checkSill(cell, room, r, room.east, 'east')			
			if sill ~= nil then list[#list + 1] = sill end
		end
	end

	return shuffle(list)
end

local function openDoor(dungeon, room, sill)
	local cell = dungeon.cell

	local door_r = sill.door_r
	local door_c = sill.door_c

	local open_r = sill.sill_r
	local open_c = sill.sill_c
	local open_dir = sill.dir

	local out_id = sill.out_id
    local di, dj = unpack(Direction.cardinal[open_dir])

    for x = 0, 2 do        
    	local r = open_r + di * x
    	local c = open_c + dj * x

    	cell[r][c] = bit.band(cell[r][c], bit.bnot(Flag.PERIMETER))
    	cell[r][c] = bit.bor(cell[r][c], Flag.ENTRANCE)
    end

    local door_type = getDoorType(dungeon)
    local door = {
    	row = door_r,
    	col = door_c,
    }

    if door_type == Flag.ARCH then
    	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], Flag.ARCH)
    	door.key = 'arch'
    	door.type = 'Archway'
    elseif door_type == Flag.DOOR then
    	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], Flag.DOOR)
    	door.key = 'open'
    	door.type = 'Unlocked Door'
    	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], bit.lshift(string.byte('o'), 24))
    elseif door_type == Flag.LOCKED then
    	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], Flag.LOCKED)
    	door.key = 'lock'
    	door.type = 'Locked Door'
    	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], bit.lshift(string.byte('x'), 24))
    elseif door_type == Flag.TRAPPED then
    	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], Flag.TRAPPED)
    	door.key = 'trap'
    	door.type = 'Trapped Door'
    	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], bit.lshift(string.byte('t'), 24))
    elseif door_type == Flag.SECRET then
    	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], Flag.SECRET)
    	door.key = 'secret'
    	door.type = 'Secret Door'
    	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], bit.lshift(string.byte('s'), 24))
    elseif door_type == Flag.PORTC then	        	
    	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], Flag.PORTC)
    	door.key = 'portc'
    	door.type = 'Portcullis'
    	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], bit.lshift(string.byte('#'), 24))
    end

    if out_id ~= nil then door.out_id = out_id end

    table.insert(room.door[open_dir], door)	
end

local connect = {}

local function openRoom(dungeon, room)
	local list = doorSills(dungeon, room)
	if #list == 0 then return end

	local n_opens = allocOpens(dungeon, room)
	local cell = dungeon.cell

	for i = 0, n_opens + 1 do
		if #list == 0 then break end

		local idx = mrandom(#list)
		local sill = table.remove(list, idx)
		local door_r = sill.door_r
		local door_c = sill.door_c
		local door_cell = cell[door_r][door_c]

		if bit.band(door_cell, Mask.DOORSPACE) == 0 then
			local out_id = sill.out_id
			if out_id ~= nil then
				local room_ids = { room.id, out_id } 			
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
	local cell = dungeon.cell
	local fixed = {}

	for _, room in ipairs(dungeon.room) do
		for dir, _ in pairsByKeys(room.door) do
			local shiny = {}

			for _, door in ipairs(room.door[dir]) do
				local door_r = door.row
				local door_c = door.col
				local door_cell = cell[door_r][door_c]

				if bit.band(door_cell, Mask.OPENSPACE) == 0 then goto continue end

				local door_id = door_r..'.'..door_c

				if fixed[door_id] ~= nil then
					shiny[#shiny + 1] = door
				else
					if door.out_id ~= nil then
						local out_id = door.out_id
						out_dir = Direction.opposite[dir]

						if dungeon.room[out_id] == nil then
							dungeon.room[out_id] = {}
							dungeon.room[out_id].door = {}
						end

						dungeon.room[out_id].door[out_dir] = door
					end
					shiny[#shiny + 1] = door
					fixed[door_id] = true
				end

				::continue::
			end

			if #shiny > 0 then
				room.door[dir] = shiny
				concat(dungeon.door, shiny)
			else
				room.door[dir] = nil
			end
		end
	end
end

local function checkTunnel(cell, r, c, check)
	local list = check.CORRIDOR

	local rows, cols = #cell, #cell[r]

	if list ~= nil then
		for _, p in ipairs(list) do
			if cell[r + p[1]][c + p[2]] ~= Flag.CORRIDOR then
				return false
			end
		end
	end

	list = check.WALLED
	if list ~= nil then
		for _, p in ipairs(list) do
			if bit.band(cell[r + p[1]][c + p[2]], Mask.OPENSPACE) ~= 0 then
				return false
			end			
		end
	end

	return true
end

local function emptyBlocks(dungeon)
	local cell = dungeon.cell

	for r = 0, dungeon.n_rows do
		for c = 0, dungeon.n_cols do
			-- clear all blocked cells, nothing to see here ...
			if bit.band(cell[r][c], Flag.BLOCKED) ~= 0 then
				cell[r][c] = Flag.NOTHING
			end

            --[[
			-- inside rooms, remove all corridors
			if bit.band(cell[r][c], Mask.OPENSPACE) == Mask.OPENSPACE then
				cell[r][c] = bit.band(cell[r][c], bit.bnot(Flag.CORRIDOR))
			end

			-- remove all perimeters around rooms
			if bit.band(cell[r][c], Flag.PERIMETER) ~= 0 then
				cell[r][c] = bit.band(cell[r][c], bit.bnot(Flag.PERIMETER))
			end

			-- only tag door cells if connected to corridor
			if (bit.band(cell[r][c], Mask.DOORSPACE) ~= 0 and 
				bit.band(cell[r][c], Flag.CORRIDOR) == 0) then
				cell[r][c] = bit.band(cell[r][c], bit.bnot(Mask.DOORSPACE))
			end
            --]]
		end
	end
end

local function collapse(dungeon, r, c, xc)
	local cell = dungeon.cell

	-- make sure row and column is within bounds
	if (r < 0 or r > dungeon.n_rows or c < 0 or c > dungeon.n_cols) then 
		return 
	end

	if bit.band(cell[r][c], Mask.OPENSPACE) == 0 then return end

	for _, dir in pairs(getKeys(xc)) do
		if checkTunnel(cell, r, c, xc[dir]) then
			for _, p in ipairs(xc[dir].CLOSE) do
				cell[r + p[1]][c + p[2]] = Flag.NOTHING
			end

			local p = xc[dir].OPEN
			if p ~= nil then
				cell[r + p[1]][c + p[2]] = bit.bor(cell[r + p[1]][c + p[2]], Flag.CORRIDOR)
			end

			p = xc[dir].RECURSE
			if p ~= nil then
				collapse(dungeon, r + p[1], c + p[2], xc)
			end
		end
	end
end

local function collapseTunnels(dungeon, percentage, xc)
	if percentage == 0 then return end

	local all = percentage == 100
	local cell = dungeon.cell

	for i = 0, dungeon.n_i - 1 do
		local r = (i * 2) + 1
		for j = 0, dungeon.n_j - 1 do
			local c = (j * 2) + 1

			if bit.band(cell[r][c], Mask.OPENSPACE) == 0 then goto continue end
			if bit.band(cell[r][c], Mask.STAIRS) ~= 0 then goto continue end
			if all or mrandom(100) < percentage then
				collapse(dungeon, r, c, xc)
			end

			::continue::
		end
	end
end

local function removeDeadends(dungeon, percentage)
	dungeon.remove_pct = percentage

	collapseTunnels(dungeon, percentage, CloseEnd)    
end

local function closeArcs(dungeon)
	collapseTunnels(dungeon, dungeon.close_arcs, CloseArc)
end

local function cleanDungeon(dungeon)	
	local percentage = RemoveDeadends[dungeon.remove_deadends]

	if percentage > 0 then
		removeDeadends(dungeon, percentage)

		-- TODO: seems buggy with stair rendering - also not sure what this adds

		if dungeon.corridor_layout == 'errant' then
			dungeon.close_arcs = dungeon.remove_pct
		elseif dungeon.corridor_layout == 'straight' then
			dungeon.close_arcs = dungeon.remove_pct
		end
	end

	if dungeon.close_arcs ~= nil then
		closeArcs(dungeon)
	end

	fixDoors(dungeon)
	emptyBlocks(dungeon)
end

local function openRooms(dungeon)
	connect = {}

	for id = 1, dungeon.n_rooms do
		openRoom(dungeon, dungeon.room[id])
	end
end

--[[
    var b;
    for (b = 1; b <= dungeon.n_rooms; b++) {
        var c = dungeon.room[b],
            d = c.id.toString(),
            e = d.length,
            g = Math.floor((c.north + c.south) / 2);
        c = Math.floor((c.west + c.east - e) / 2) + 1;
        var f;
        for (f = 0; f < e; f++) dungeon.cell[g][c + f] |= d.charCodeAt(f) << 24
    }
    return a
]]

local function labelRooms(dungeon)
	local cell = dungeon.cell

	for id = 1, dungeon.n_rooms do
		local room = dungeon.room[id]
		local label = room.id
		local len = string.len(label)
		local label_r = mfloor((room.north + room.south) / 2)
		local label_c = mfloor((room.west + room.east - len) / 2) + 1

		for c = 0, len - 1 do
			local char = string.sub(label, c + 1)
			local mask = bit.lshift(string.byte(char), 24)
			cell[label_r][label_c + c] = bit.bor(cell[label_r][label_c + c], mask)
		end
	end
end

local function tunnelDirs(dungeon, last_dir)
	-- TODO: what does it matter if we use sorted table dj_dirs while
	-- afterwards shuffling as in original code?
	local keys = getKeys(Direction.cardinal)
	local dirs = shuffle(keys)
	local p = dungeon.straight_pct

	if last_dir ~= nil and p ~= nil then
		if mrandom(100) < p then
			table.insert(dirs, 1, last_dir)
		end
	end

	return dirs
end

local function delveTunnel(dungeon, this_r, this_c, next_r, next_c)
	local cell = dungeon.cell

	local tbl_r, tbl_c = { this_r, next_r }, { this_c, next_c }
	
	table.sort(tbl_r)
	local r1, r2 = unpack(tbl_r)

	table.sort(tbl_c)
	local c1, c2 = unpack(tbl_c)

	for r = r1, r2 do
		for c = c1, c2 do
			cell[r][c] = bit.band(cell[r][c], bit.bnot(Flag.ENTRANCE))
			cell[r][c] = bit.bor(cell[r][c], Flag.CORRIDOR)
		end
	end

	return true
end

local function soundTunnel(dungeon, mid_r, mid_c, next_r, next_c)
	if next_r < 0 or next_r > dungeon.n_rows then return false end
	if next_c < 0 or next_c > dungeon.n_cols then return false end

	local cell = dungeon.cell
	local tbl_r, tbl_c = { mid_r, next_r }, { mid_c, next_c }

	table.sort(tbl_r)
	local r1, r2 = unpack(tbl_r)

	table.sort(tbl_c)
	local c1, c2 = unpack(tbl_c)

	for r = r1, r2 do
		for c = c1, c2 do
			if bit.band(cell[r][c], Mask.BLOCK_CORR) ~= 0 then return false end
		end
	end	

	return true
end

local function openTunnel(dungeon, i, j, dir)
    local di, dj = unpack(Direction.cardinal[dir])
	local this_r = (i * 2) + 1
	local this_c = (j * 2) + 1
	local next_r = (i + di) * 2 + 1
	local next_c = (j + dj) * 2 + 1
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
        local di, dj = unpack(Direction.cardinal[dir])
		if openTunnel(dungeon, i, j, dir) then
			local next_i = i + di
			local next_j = j + dj

			tunnel(dungeon, next_i, next_j, dir)
		end
	end
end

local function corridors(dungeon)
	local cell = dungeon.cell

	dungeon.straight_pct = CorridorLayout[dungeon.corridor_layout]

	for i = 1, dungeon.n_i - 1 do
		local r = i * 2 + 1
		for j = 1, dungeon.n_j - 1 do
			local c = j * 2 + 1

			if bit.band(cell[r][c], Flag.CORRIDOR) == Flag.CORRIDOR then goto continue end

			tunnel(dungeon, i, j, last_dir)

			::continue::
		end
	end
end

local function stairEnds(dungeon)
	local cell = dungeon.cell
	local list = {}

	for i = 0, dungeon.n_i - 1 do
		local r = (i * 2) + 1
		for j = 0, dungeon.n_j - 1 do
			local c = (j * 2) + 1

			if bit.band(cell[r][c], Flag.CORRIDOR) == 0 then goto continue end
			if bit.band(cell[r][c], Mask.STAIRS) ~= 0 then goto continue end

			for _, dir in ipairs(getKeys(StairEnd)) do
				if checkTunnel(cell, r, c, StairEnd[dir]) then
					local s_end = { row = r, col = c, dir = dir }
					local n = StairEnd[dir].NEXT
					s_end.next_row = s_end.row + n[1]
					s_end.next_col = s_end.col + n[2]

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
	local n = AddStairs[dungeon.add_stairs]

	if n == 0 then return end

	if n == mhuge then
		n = dungeon.n_cols * dungeon.n_rows
		n = 2 + mrandom(n / 1e3)
	end

	local list = stairEnds(dungeon)
	local cell = dungeon.cell

	shuffle(list)

	for i = 0, n - 1 do
		if #list == 0 then return end

		local stair = table.remove(list)

		local r, next_r = stair.row, stair.next_row
		local c, next_c = stair.col, stair.next_col
		local s_type = i < 2 and (i + 1) or mrandom(2)

		if s_type == 1 then
			cell[r][c] = bit.bor(cell[r][c], Flag.STAIR_DN)
			cell[r][c] = bit.bor(cell[r][c], bit.lshift(string.byte('d'), 24))
			stair.key = 'down'
		else
			cell[r][c] = bit.bor(cell[r][c], Flag.STAIR_UP)
			cell[r][c] = bit.bor(cell[r][c], bit.lshift(string.byte('u'), 24))
			stair.key = 'up'
		end

		table.insert(dungeon.stair, stair)
	end
end

local function generate(options)
	love.math.setRandomSeed(options.seed)

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
