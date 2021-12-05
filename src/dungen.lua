-- LuaJIT 2.1 required
local ffi = require'ffi'

DunGen = {}

local Flags = {
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

-- directions
local di = { ["north"] = -1, ["south"] = 1, ["west"] =  0, ["east"] = 0 }
local dj = { ["north"] =  0, ["south"] = 0, ["west"] = -1, ["east"] = 1 }
--my @dj_dirs = sort keys %{ $dj };

local opposite = {
	["north"] = "south",
	["south"] = "north",
	["east"] = "west",
	["west"] = "east",
}

--[[ TODO: 
	* Improve implementation, all layout names should be public
	or perhaps just forward layout tables instead, so users 
	can provide custom layouts
	* Donjon's JavaScript implementation adds additional options 
	for layouts and aspect ratios
--]]
local dungeonLayout = {
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
	}
}

local connect = nil

local function merge(tbl1, tbl2)
	for k, v in pairs(tbl2) do
		assert(tbl1[k] ~= nil, "invalid key: " .. k)

		tbl1[k] = v
	end 

	return tbl1
end

local function getKeys(tbl)
	local n = 0
	local keys = {}

	for k, v in pairs(tbl) do
		n = n + 1
		keys[n] = k
	end

	return keys
end

function shuffle(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end

local function getOpts()
	return {
		["seed"] = love.timer.getTime(),
		["n_rows"] = 39, -- must be an odd number
		["n_cols"] = 39, -- must be an odd number
		["dungeon_layout"] = 'None',
		["room_min"] = 3, -- minimum room size
		["room_max"] = 9, -- maximum room size
		["room_layout"] = 'Scattered', -- Packed, Scattered
		["corridor_layout"] = "Bent",
		["remove_deadends"] = 50, -- percentage
		["add_stairs"] = 2, -- number of stairs
		["map_style"] = 'Standard',
		["cell_size"] = 18, -- pixels
	}
end

local function getDoorType()
	local i = math.floor(love.math.random(110))

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
			cell[r][c] = mask[math.floor(r * r_x + 0.5)][math.floor(c * c_x + 0.5)] == 1 and Flags.NOTHING or Flags.BLOCKED
		end
	end
end

local function roundMask(dungeon)
	local center_r = math.floor(dungeon["n_rows"] / 2)
	local center_c = math.floor(dungeon["n_cols"] / 2)
	local cell = dungeon["cell"]

	for r = 0, dungeon["n_rows"] do
		for c = 0, dungeon["n_cols"] do
			local d = math.sqrt(
				math.pow((r - center_r), 2) + 
				math.pow((c - center_c), 2))
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
	elseif dungeonLayout[mask] ~= nil then
		maskCells(dungeon, dungeonLayout[mask])		
	end
end

--[[
sub sound_room {
    my ($dungeon,$r1,$c1,$r2,$c2) = @_;
    my $cell = $dungeon->{'cell'};
    my $hit;
    
    my $r; for ($r = $r1; $r <= $r2; $r++) {
        my $c; for ($c = $c1; $c <= $c2; $c++) {
            if ($cell->[$r][$c] & $BLOCKED) {
                return { 'blocked' => 1 };
            }
            if ($cell->[$r][$c] & $ROOM) {
                my $id = ($cell->[$r][$c] & $ROOM_ID) >> 6;
                $hit->{$id} += 1;
            }
        }
    }
    return $hit;
}
]]
local function soundRoom(dungeon, r1, c1, r2, c2)
	local cell = dungeon["cell"]
	local hit = {}

	for r = r1, r2, 1 do
		for c = c1, c2, 1 do
			if bit.band(cell[r][c], Flags.BLOCKED) == Flags.BLOCKED then
				return { ["blocked"] = true }
			end

			if bit.band(cell[r][c], Flags.ROOM) == Flags.ROOM then
				local id = bit.rshift(bit.band(cell[r][c], Flags.ROOM_ID), 6)
				local sId = tostring(id)
				hit[sId] = id + 1
			end
		end
	end

	return hit
end

--[[
sub set_room {
    my ($dungeon,$proto) = @_;
    my $base = $dungeon->{'room_base'};
    my $radix = $dungeon->{'room_radix'};
    
    unless (defined $proto->{'height'}) {
        if (defined $proto->{'i'}) {
            my $a = $dungeon->{'n_i'} - $base - $proto->{'i'};
            $a = 0 if ($a < 0);
            my $r = ($a < $radix) ? $a : $radix;
            
            $proto->{'height'} = int(rand($r)) + $base;
        } else {
            $proto->{'height'} = int(rand($radix)) + $base;
        }
    }
    unless (defined $proto->{'width'}) {
        if (defined $proto->{'j'}) {
            my $a = $dungeon->{'n_j'} - $base - $proto->{'j'};
            $a = 0 if ($a < 0);
            my $r = ($a < $radix) ? $a : $radix;
            
            $proto->{'width'} = int(rand($r)) + $base;
        } else {
            $proto->{'width'} = int(rand($radix)) + $base;
        }
    }
    unless (defined $proto->{'i'}) {
        $proto->{'i'} = int(rand($dungeon->{'n_i'} - $proto->{'height'}));
    }
    unless (defined $proto->{'j'}) {
        $proto->{'j'} = int(rand($dungeon->{'n_j'} - $proto->{'width'}));
    }
    return $proto;
}
]]

local function setRoom(dungeon, proto)
	local base = dungeon["room_base"]
	local radix = dungeon["room_radix"]

	if proto["height"] == nil then
		if proto["i"] ~= nil then
			local a = dungeon["n_i"] - base - proto["i"]
			a = math.max(a, 0)
			local r = math.min(a, radix)
			proto["height"] = math.floor(love.math.random(r) + base)
		else			
			proto["height"] = math.floor(love.math.random(radix)) + base
		end
	end

	if proto["width"] == nil then
		if proto["j"] ~= nil then
			local a = math.max(dungeon["n_j"] - base - proto["j"], 0)
			local r = math.min(a, radix)
			proto["width"] = math.floor(love.math.random(r) + base)
		else
			proto["width"] = math.floor(love.math.random(radix)) + base
		end
	end

	if proto["i"] == nil then
		proto["i"] = math.floor(love.math.random(dungeon["n_i"] - proto["height"]))
	end

	if proto["j"] == nil then
		proto["j"] = math.floor(love.math.random(dungeon["n_j"] - proto["width"]))
	end

	print('\nadd room:')
	for k, v in pairs(proto) do
		print(' ' .. k, v)
	end
end

--[[
sub emplace_room {
    my ($dungeon,$proto) = @_;
    return $dungeon if ($dungeon->{'n_rooms'} == 999);
    my ($r,$c);
    my $cell = $dungeon->{'cell'};
    
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # room position and size
    
    $proto = &set_room($dungeon,$proto);
    
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # room boundaries
    
    my $r1 = ( $proto->{'i'}                       * 2) + 1;
    my $c1 = ( $proto->{'j'}                       * 2) + 1;
    my $r2 = (($proto->{'i'} + $proto->{'height'}) * 2) - 1;
    my $c2 = (($proto->{'j'} + $proto->{'width'} ) * 2) - 1;
    
    return $dungeon if ($r1 < 1 || $r2 > $dungeon->{'max_row'});
    return $dungeon if ($c1 < 1 || $c2 > $dungeon->{'max_col'});
    
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # check for collisions with existing rooms
    
    my $hit = &sound_room($dungeon,$r1,$c1,$r2,$c2);
    return $dungeon if ($hit->{'blocked'});
    my @hit_list = keys %{ $hit };
    my $n_hits = scalar @hit_list;
    my $room_id;
    
    if ($n_hits == 0) {
        $room_id = $dungeon->{'n_rooms'} + 1;
        $dungeon->{'n_rooms'} = $room_id;
    } else {
        return $dungeon;
    }
    $dungeon->{'last_room_id'} = $room_id;
    
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # emplace room
    
    for ($r = $r1; $r <= $r2; $r++) {
        for ($c = $c1; $c <= $c2; $c++) {
            if ($cell->[$r][$c] & $ENTRANCE) {
                $cell->[$r][$c] &= ~ $ESPACE;
            } elsif ($cell->[$r][$c] & $PERIMETER) {
                $cell->[$r][$c] &= ~ $PERIMETER;
            }
            $cell->[$r][$c] |= $ROOM | ($room_id << 6);
        }
    }
    my $height = (($r2 - $r1) + 1) * 10;
    my $width = (($c2 - $c1) + 1) * 10;
    
    my $room_data = {
        'id' => $room_id, 'row' => $r1, 'col' => $c1,
        'north' => $r1, 'south' => $r2, 'west' => $c1, 'east' => $c2,
        'height' => $height, 'width' => $width, 'area' => ($height * $width)
    };
    $dungeon->{'room'}[$room_id] = $room_data;
    
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # block corridors from room boundary
    # check for door openings from adjacent rooms
    
    for ($r = $r1 - 1; $r <= $r2 + 1; $r++) {
        unless ($cell->[$r][$c1 - 1] & ($ROOM | $ENTRANCE)) {
            $cell->[$r][$c1 - 1] |= $PERIMETER;
        }
        unless ($cell->[$r][$c2 + 1] & ($ROOM | $ENTRANCE)) {
            $cell->[$r][$c2 + 1] |= $PERIMETER;
        }
    }
    for ($c = $c1 - 1; $c <= $c2 + 1; $c++) {
        unless ($cell->[$r1 - 1][$c] & ($ROOM | $ENTRANCE)) {
            $cell->[$r1 - 1][$c] |= $PERIMETER;
        }
        unless ($cell->[$r2 + 1][$c] & ($ROOM | $ENTRANCE)) {
            $cell->[$r2 + 1][$c] |= $PERIMETER;
        }
    }
    
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    
    return $dungeon;
}
]]

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

	local hitList = getKeys(hit)
	local hits = #hitList
	local room_id = nil

	if hits == 0 then
		room_id = dungeon["n_rooms"] + 1
		dungeon["n_rooms"] = room_id
	else
		return
	end

	dungeon["last_room_id"] = room_id

--[[
	for ($r = $r1; $r <= $r2; $r++) {
        for ($c = $c1; $c <= $c2; $c++) {
            if ($cell->[$r][$c] & $ENTRANCE) {
                $cell->[$r][$c] &= ~ $ESPACE;
            } elsif ($cell->[$r][$c] & $PERIMETER) {
                $cell->[$r][$c] &= ~ $PERIMETER;
            }
            $cell->[$r][$c] |= $ROOM | ($room_id << 6);
        }
    }
    my $height = (($r2 - $r1) + 1) * 10;
    my $width = (($c2 - $c1) + 1) * 10;
    
    my $room_data = {
        'id' => $room_id, 'row' => $r1, 'col' => $c1,
        'north' => $r1, 'south' => $r2, 'west' => $c1, 'east' => $c2,
        'height' => $height, 'width' => $width, 'area' => ($height * $width)
    };
    $dungeon->{'room'}[$room_id] = $room_data;
]]
	
	for r = r1, r2, 1 do
		for c = c1, c2, 1 do
			if bit.band(cell[r][c], Flags.ENTRANCE) == Flags.ENTRANCE then
				cell[r][c] = bit.band(cell[r][c], bit.bnot(Flags.ESPACE))
			elseif bit.band(cell[r][c], Flags.PERIMETER) == Flags.PERIMETER then
				cell[r][c] = bit.band(cell[r][c], bit.bnot(Flags.PERIMETER))
			end
			cell[r][c] = bit.bor(cell[r][c], Flags.ROOM, bit.lshift(room_id, 6))
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

	--[[    
    for ($r = $r1 - 1; $r <= $r2 + 1; $r++) {
        unless ($cell->[$r][$c1 - 1] & ($ROOM | $ENTRANCE)) {
            $cell->[$r][$c1 - 1] |= $PERIMETER;
        }
        unless ($cell->[$r][$c2 + 1] & ($ROOM | $ENTRANCE)) {
            $cell->[$r][$c2 + 1] |= $PERIMETER;
        }
    }
    for ($c = $c1 - 1; $c <= $c2 + 1; $c++) {
        unless ($cell->[$r1 - 1][$c] & ($ROOM | $ENTRANCE)) {
            $cell->[$r1 - 1][$c] |= $PERIMETER;
        }
        unless ($cell->[$r2 + 1][$c] & ($ROOM | $ENTRANCE)) {
            $cell->[$r2 + 1][$c] |= $PERIMETER;
        }
    }
	]]

	for r = r1 - 1, r2 + 1, 1 do
		if bit.band(cell[r][c1 - 1], bit.bor(Flags.ROOM, Flags.ENTRANCE)) == 0 then
			cell[r][c1 - 1] = bit.bor(cell[r][c1 - 1], Flags.PERIMETER)
		end
		if bit.band(cell[r][c1 + 1], bit.bor(Flags.ROOM, Flags.ENTRANCE)) == 0 then
			cell[r][c1 + 1] = bit.bor(cell[r][c1 + 1], Flags.PERIMETER)
		end
	end

	for c = c1 - 1, c2 + 1, 1 do
		if bit.band(cell[r1 - 1][c], bit.bor(Flags.ROOM, Flags.ENTRANCE)) == 0 then
			cell[r1 - 1][c] = bit.bor(cell[r1 - 1][c], Flags.PERIMETER)
		end
		if bit.band(cell[r2 + 1][c], bit.bor(Flags.ROOM, Flags.ENTRANCE)) == 0 then
			cell[r2 + 1][c] = bit.bor(cell[r2 + 1][c], Flags.PERIMETER)
		end		
	end
end

local function allocRooms(dungeon, room_max)
	local dungeon_area = dungeon["n_cols"] * dungeon["n_rows"]
	local room_area = room_max * room_max
	local n_rooms = math.floor(dungeon_area / room_area)

	return n_rooms
end

local function packRooms(dungeon)
	local cell = dungeon["cell"]

	for i = 0, dungeon["n_i"] - 1 do
		local r = i * 2 + 1
		for j = 0, dungeon["n_j"] - 1 do
			local c = j * 2 + 1

			local has_room = bit.band(cell[r][c], Flags.ROOM) == Flags.ROOM
			local is_ignore = (i == 0 or j == 0) and love.math.random(0, 1) == 1

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

--[[
sub alloc_opens {
    my ($dungeon,$room) = @_;
    my $room_h = (($room->{'south'} - $room->{'north'}) / 2) + 1;
    my $room_w = (($room->{'east'} - $room->{'west'}) / 2) + 1;
    my $flumph = int(sqrt($room_w * $room_h));
    my $n_opens = $flumph + int(rand($flumph));
    
    return $n_opens;
}
]]

local function allocOpens(dungeon, room)
	local room_h = (room["south"] - room["north"]) / 2 + 1
	local room_w = (room["east"] - room["west"]) / 2 + 1
	local flumph = math.floor(math.sqrt(room_w * room_h))
	local n_opens = flumph + math.floor(love.math.random(flumph))

	return n_opens
end

--[[
sub check_sill {
    my ($cell,$room,$sill_r,$sill_c,$dir) = @_;
    my $door_r = $sill_r + $di->{$dir};
    my $door_c = $sill_c + $dj->{$dir};
    my $door_cell = $cell->[$door_r][$door_c];
    return unless ($door_cell & $PERIMETER);
    return if ($door_cell & $BLOCK_DOOR);
    my $out_r  = $door_r + $di->{$dir};
    my $out_c  = $door_c + $dj->{$dir};
    my $out_cell = $cell->[$out_r][$out_c];
    return if ($out_cell & $BLOCKED);
    
    my $out_id; if ($out_cell & $ROOM) {
        $out_id = ($out_cell & $ROOM_ID) >> 6;
        return if ($out_id == $room->{'id'});
    }
    return {
        'sill_r'    => $sill_r,
        'sill_c'    => $sill_c,
        'dir'       => $dir,
        'door_r'    => $door_r,
        'door_c'    => $door_c,
        'out_id'    => $out_id,
    };
}
]]

local function checkSill(cell, room, sill_r, sill_c, dir)
	local door_r = sill_r + di[dir]
	local door_c = sill_c + dj[dir]
	local door_cell = cell[door_r][door_c]
	if bit.band(door_cell, Flags.PERIMETER) ~= Flags.PERIMETER then return end
	if bit.band(door_cell, Flags.BLOCK_DOOR) == Flags.BLOCK_DOOR then return end
	local out_r = door_r + di[dir]
	local out_c = door_c + dj[dir]
	local out_cell = cell[out_r][out_c]
	if bit.band(out_cell, Flags.BLOCKED) == Flags.BLOCKED then return end

	local out_id = nil

	if bit.band(out_cell, Flags.ROOM) == Flags.ROOM then
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

--[[
sub door_sills {
    my ($dungeon,$room) = @_;
    my $cell = $dungeon->{'cell'};
    my @list;
    
    if ($room->{'north'} >= 3) {
        my $c; for ($c = $room->{'west'}; $c <= $room->{'east'}; $c += 2) {
            my $sill = &check_sill($cell,$room,$room->{'north'},$c,'north');
            push(@list,$sill) if ($sill);
        }
    }
    if ($room->{'south'} <= ($dungeon->{'n_rows'} - 3)) {
        my $c; for ($c = $room->{'west'}; $c <= $room->{'east'}; $c += 2) {
            my $sill = &check_sill($cell,$room,$room->{'south'},$c,'south');
            push(@list,$sill) if ($sill);
        }
    }
    if ($room->{'west'} >= 3) {
        my $r; for ($r = $room->{'north'}; $r <= $room->{'south'}; $r += 2) {
            my $sill = &check_sill($cell,$room,$r,$room->{'west'},'west');
            push(@list,$sill) if ($sill);
        }
    }
    if ($room->{'east'} <= ($dungeon->{'n_cols'} - 3)) {
        my $r; for ($r = $room->{'north'}; $r <= $room->{'south'}; $r += 2) {
            my $sill = &check_sill($cell,$room,$r,$room->{'east'},'east');
            push(@list,$sill) if ($sill);
        }
    }
    return &shuffle(@list);
}
]]

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

--[[
sub open_room {
    my ($dungeon,$room) = @_;
    my @list = &door_sills($dungeon,$room);
    return $dungeon unless (@list);
    my $n_opens = &alloc_opens($dungeon,$room);
    my $cell = $dungeon->{'cell'};
    
    my $i; for ($i = 0; $i < $n_opens; $i++) {
        my $sill = splice(@list,int(rand(@list)),1);
        last unless ($sill);
        my $door_r = $sill->{'door_r'};
        my $door_c = $sill->{'door_c'};
        my $door_cell = $cell->[$door_r][$door_c];
        redo if ($door_cell & $DOORSPACE);
        
        my $out_id; if ($out_id = $sill->{'out_id'}) {
            my $connect = join(',',(sort($room->{'id'},$out_id)));
            redo if ($dungeon->{'connect'}{$connect}++);
        }
        my $open_r = $sill->{'sill_r'};
        my $open_c = $sill->{'sill_c'};
        my $open_dir = $sill->{'dir'};
        
        # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        # open door
        
        my $x; for ($x = 0; $x < 3; $x++) {
            my $r = $open_r + ($di->{$open_dir} * $x);
            my $c = $open_c + ($dj->{$open_dir} * $x);
            
            $cell->[$r][$c] &= ~ $PERIMETER;
            $cell->[$r][$c] |= $ENTRANCE;
        }
        my $door_type = &door_type();
        my $door = { 'row' => $door_r, 'col' => $door_c };
        
        if ($door_type == $ARCH) {
            $cell->[$door_r][$door_c] |= $ARCH;
            $door->{'key'} = 'arch'; $door->{'type'} = 'Archway';
        } elsif ($door_type == $DOOR) {
            $cell->[$door_r][$door_c] |= $DOOR;
            $cell->[$door_r][$door_c] |= (ord('o') << 24);
            $door->{'key'} = 'open'; $door->{'type'} = 'Unlocked Door';
        } elsif ($door_type == $LOCKED) {
            $cell->[$door_r][$door_c] |= $LOCKED;
            $cell->[$door_r][$door_c] |= (ord('x') << 24);
            $door->{'key'} = 'lock'; $door->{'type'} = 'Locked Door';
        } elsif ($door_type == $TRAPPED) {
            $cell->[$door_r][$door_c] |= $TRAPPED;
            $cell->[$door_r][$door_c] |= (ord('t') << 24);
            $door->{'key'} = 'trap'; $door->{'type'} = 'Trapped Door';
        } elsif ($door_type == $SECRET) {
            $cell->[$door_r][$door_c] |= $SECRET;
            $cell->[$door_r][$door_c] |= (ord('s') << 24);
            $door->{'key'} = 'secret'; $door->{'type'} = 'Secret Door';
        } elsif ($door_type == $PORTC) {
            $cell->[$door_r][$door_c] |= $PORTC;
            $cell->[$door_r][$door_c] |= (ord('#') << 24);
            $door->{'key'} = 'portc'; $door->{'type'} = 'Portcullis';
        }
        $door->{'out_id'} = $out_id if ($out_id);
        push(@{ $room->{'door'}{$open_dir} },$door) if ($door);
    }
    return $dungeon;
}
]]

--[[
function open_room(a, b) {
    var c = door_sills(a, b);
    if (!c.length) return a;
    var d = alloc_opens(a, b),
        e;
    for (e = 0; e < d; e++) {
        var g = c.splice(random(c.length), 1).shift();
        if (!g) break;
        var f = g.door_r,
            h = g.door_c;
        f = a.cell[f][h];
        if (!(f & DOORSPACE))
            if (f = g.out_id) {
                f = [b.id, f].sort(cmp_int).join(",");
                if (!connect[f]) {
                    a = open_door(a, b, g);
                    connect[f] = 1
                }
            } else a = open_door(a, b, g)
    }
    return a
}
]]

local function openRoom(dungeon, room)
	local list = doorSills(dungeon, room)
	if #list == 0 then return end

	local n_opens = allocOpens(dungeon, room)
	local cell = dungeon["cell"]

	for i = 0, n_opens do
		if #list == 0 then break end

		local idx = love.math.random(#list)
		local sill = table.remove(list, idx)
		local door_r = sill["door_r"]
		local door_c = sill["door_c"]
		local door_cell = cell[door_r][door_c]

		if bit.band(door_cell, Flags.DOORSPACE) == Flags.DOORSPACE then 
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
		end

		local open_r = sill["sill_r"]
		local open_c = sill["sill_c"]
		local open_dir = sill["dir"]
	
        for x = 0, 2 do
        	local r = open_r + di[open_dir] * x
        	local c = open_c + dj[open_dir] * x

        	cell[r][c] = bit.band(cell[r][c], bit.bnot(Flags.PERIMETER))
        	cell[r][c] = bit.bor(cell[r][c], Flags.ENTRANCE)
        end

        local doorType = getDoorType()
        local door = {
        	["row"] = door_r,
        	["col"] = door_c,
        }

        if doorType == Flags.ARCH then
        	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], Flags.ARCH)
        	door["key"] = "arch"
        	door["type"] = "Archway"
        elseif doorType == Flags.DOOR then
        	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], Flags.DOOR)
        	door["key"] = "open"
        	door["type"] = "Unlocked Door"
        elseif doorType == Flags.LOCKED then
        	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], Flags.LOCKED)
        	door["key"] = "lock"
        	door["type"] = "Locked Door"
        elseif doorType == Flags.TRAPPED then
        	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], Flags.TRAPPED)
        	door["key"] = "trap"
        	door["type"] = "Trapped Door"
        elseif doorType == Flags.SECRET then
        	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], Flags.SECRET)
        	door["key"] = "secret"
        	door["type"] = "Secret Door"
        elseif doorType == Flags.PORTC then	        	
        	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], Flags.PORTC)
        	door["key"] = "portc"
        	door["type"] = "Portcullis"
        end

        if out_id ~= nil then door["out_id"] = out_id end

        table.insert(room["door"][open_dir], door)

--[[
        if ($door_type == $ARCH) {
            $cell->[$door_r][$door_c] |= $ARCH;
            $door->{'key'} = 'arch'; $door->{'type'} = 'Archway';
        } elsif ($door_type == $DOOR) {
            $cell->[$door_r][$door_c] |= $DOOR;
            $cell->[$door_r][$door_c] |= (ord('o') << 24);
            $door->{'key'} = 'open'; $door->{'type'} = 'Unlocked Door';
        } elsif ($door_type == $LOCKED) {
            $cell->[$door_r][$door_c] |= $LOCKED;
            $cell->[$door_r][$door_c] |= (ord('x') << 24);
            $door->{'key'} = 'lock'; $door->{'type'} = 'Locked Door';
        } elsif ($door_type == $TRAPPED) {
            $cell->[$door_r][$door_c] |= $TRAPPED;
            $cell->[$door_r][$door_c] |= (ord('t') << 24);
            $door->{'key'} = 'trap'; $door->{'type'} = 'Trapped Door';
        } elsif ($door_type == $SECRET) {
            $cell->[$door_r][$door_c] |= $SECRET;
            $cell->[$door_r][$door_c] |= (ord('s') << 24);
            $door->{'key'} = 'secret'; $door->{'type'} = 'Secret Door';
        } elsif ($door_type == $PORTC) {
            $cell->[$door_r][$door_c] |= $PORTC;
            $cell->[$door_r][$door_c] |= (ord('#') << 24);
            $door->{'key'} = 'portc'; $door->{'type'} = 'Portcullis';
        }
        $door->{'out_id'} = $out_id if ($out_id);
        push(@{ $room->{'door'}{$open_dir} },$door) if ($door);
]]

        ::continue::
	end
end

--[[
    my $id; for ($id = 1; $id <= $dungeon->{'n_rooms'}; $id++) {
        $dungeon = &open_room($dungeon,$dungeon->{'room'}[$id]);
    }
    delete($dungeon->{'connect'});
    return $dungeon;
]]

local function openRooms(dungeon)
	connect = {}

	for id = 1, dungeon["n_rooms"] do
		openRoom(dungeon, dungeon["room"][id])
	end
end

function DunGen.generate(options)
	local options = merge(getOpts(), options or {})

	print('\ngenerate dungeon:')
	for k, v in pairs(options) do
		print(' ' .. k, v)
	end

	love.math.setRandomSeed(options["seed"])

	local dungeon = {}

	dungeon["n_i"] = math.floor(options["n_rows"] / 2)
	dungeon["n_j"] = math.floor(options["n_cols"] / 2)
	dungeon["n_rows"] = dungeon["n_i"] * 2
	dungeon["n_cols"] = dungeon["n_j"] * 2
	dungeon["max_row"] = dungeon["n_rows"] - 1
	dungeon["max_col"] = dungeon["n_cols"] - 1
	dungeon["n_rooms"] = 0
	dungeon["room"] = {}

	-- TODO: perhaps ugly to copy
	dungeon["cell_size"] = options["cell_size"]

	local max = options["room_max"]
	local min = options["room_min"]
	dungeon["room_base"] = math.floor((min + 1) / 2)
	dungeon["room_radix"] = math.floor((max - min) / 2 + 1)

	print('\ndungeon config:')
	for k, v in pairs(dungeon) do
		print(' ' .. k, v)
	end

	local mask = options["dungeon_layout"]
	initCells(dungeon, mask)

	local roomLayout, roomMax = options["room_layout"], options["room_max"]
	emplaceRooms(dungeon, roomLayout, roomMax)

	openRooms(dungeon)

	for k, v in ipairs(dungeon["room"]) do
		for k2, v2 in pairs(v) do
			print(k2, v2)
		end
		print()
	end

	return dungeon
end

--[[
    var b = {
        map_style: a.map_style,
        grid: a.grid
    };
    b.cell_size = a.cell_size;
    b.width = (a.n_cols + 1) * b.cell_size + 1;
    b.height = (a.n_rows + 1) * b.cell_size + 1;
    b.max_x = b.width - 1;
    b.max_y = b.height - 1;
    a = Math.floor(b.cell_size * 0.75);
    b.font = a.toString() + "px sans-serif";
    return b
]]

--[[  
    my $image = {
        'cell_size' => $dungeon->{'cell_size'},
        'map_style' => $dungeon->{'map_style'},
    };
    $image->{'width'}  = (($dungeon->{'n_cols'} + 1)
    *   $image->{'cell_size'}) + 1;
    $image->{'height'} = (($dungeon->{'n_rows'} + 1)
    *   $image->{'cell_size'}) + 1;
    $image->{'max_x'}  = $image->{'width'} - 1;
    $image->{'max_y'}  = $image->{'height'} - 1;
    
    if ($image->{'cell_size'} > 16) {
        $image->{'font'} = gdLargeFont;
    } elsif ($image->{'cell_size'} > 12) {
        $image->{'font'} = gdSmallFont;
    } else {
        $image->{'font'} = gdTinyFont;
    }
    $image->{'char_w'} = $image->{'font'}->width;
    $image->{'char_h'} = $image->{'font'}->height;
    $image->{'char_x'} = int(($image->{'cell_size'}
    -      $image->{'char_w'}) / 2) + 1;
    $image->{'char_y'} = int(($image->{'cell_size'}
    -      $image->{'char_h'}) / 2) + 1;
    
    return $image;
]]

local function scaleDungeon(dungeon)
	local image = {
		["cell_size"] = dungeon["cell_size"],
		["map_style"] = dungeon["map_style"],
	}
	image["width"] = (dungeon["n_cols"] + 1) * (image["cell_size"]) + 1
	image["height"] = (dungeon["n_rows"] + 1) * (image["cell_size"]) + 1
	image["max_x"] = image["width"] - 1
	image["max_y"] = image["height"] - 1

	return image
end

--[[
    standard: {
        colors: {
            fill: "#000000",
            open: "#ffffff",
            open_grid: "#cccccc"
        }
    },
]]

local function getPalette()
	return {
		["colors"] = {
			["fill"] = { 0.0, 0.0, 0.0, 1.0 },
			["open"] = { 1.0, 1.0, 1.0, 1.0 },
			["open_grid"] = { 0.5, 0.5, 0.5, 1.0 },
		},
		["black"] = { 0.0, 0.0, 0.0, 1.0 },
		["white"] = { 1.0, 1.0, 1.0, 1.0 },
	}
end

--[[
sub square_grid {
    my ($dungeon,$image,$color,$ih) = @_;
    my $dim = $image->{'cell_size'};
    
    my $x; for ($x = 0; $x <= $image->{'max_x'}; $x += $dim) {
        $ih->line($x,0,$x,$image->{'max_y'},$color);
    }
    my $y; for ($y = 0; $y <= $image->{'max_y'}; $y += $dim) {
        $ih->line(0,$y,$image->{'max_x'},$y,$color);
    }
    return $ih;
}
]]

--[[
    my ($dungeon,$image,$color,$ih) = @_;
    my $dim = $image->{'cell_size'};
    
    my $x; for ($x = 0; $x <= $image->{'max_x'}; $x += $dim) {
        $ih->line($x,0,$x,$image->{'max_y'},$color);
    }
    my $y; for ($y = 0; $y <= $image->{'max_y'}; $y += $dim) {
        $ih->line(0,$y,$image->{'max_x'},$y,$color);
    }
    return $ih;
]]

local function squareGrid(dungeon, image, color, canvas)
	local dim = image["cell_size"]

	love.graphics.setColor(0.0, 0.0, 0.0)

	for x = 0, image["max_x"], dim do
		love.graphics.line(x, 0, x, image["max_y"])
	end

	for y = 0, image["max_y"], dim do
		love.graphics.line(0, y, image["max_x"], y)
	end
	
	love.graphics.setColor(1.0, 1.0, 1.0)
end

local function imageGrid(dungeon, image, color, canvas)
	squareGrid(dungeon, image, color, canvas)
end

local function fillImage(dungeon, image, color, canvas)
	love.graphics.clear(color)

	imageGrid(dungeon, image, color, canvas)
end

--[[
sub open_cells {
    my ($dungeon,$image,$ih) = @_;
    my $cell = $dungeon->{'cell'};
    my $dim = $image->{'cell_size'};
    my $base = $image->{'base_layer'};
    
    my $r; for ($r = 0; $r <= $dungeon->{'n_rows'}; $r++) {
        my $y1 = $r * $dim;
        my $y2 = $y1 + $dim;
        
        my $c; for ($c = 0; $c <= $dungeon->{'n_cols'}; $c++) {
            next unless ($cell->[$r][$c] & $OPENSPACE);
            
            my $x1 = $c * $dim;
            my $x2 = $x1 + $dim;
            
            $ih->copy($base,$x1,$y1,$x1,$y1,($dim+1),($dim+1));
        }
    }
    return $ih;
}

]]

local function openCells(dungeon, image, canvas)
	local cell = dungeon["cell"]
	local dim = image["cell_size"]

	love.graphics.setColor(0.0, 0.0, 0.0, 1.0)

	for r = 0, dungeon["n_rows"] do
		for c = 0, dungeon["n_cols"] do
			-- TODO: should check for Flags.OPENSPACE instead, but currently no open space assigned
			if bit.band(cell[r][c], Flags.OPENSPACE) == 0 then
				local x = c * dim
				local y = r * dim

				love.graphics.rectangle('fill', x, y, dim, dim)
			end
		end
	end

	love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
end

function DunGen.getTexture(dungeon)
	local image = scaleDungeon(dungeon)
	local palette = getPalette()

	local canvas = love.graphics.newCanvas(image["width"], image["height"])
	love.graphics.setCanvas(canvas)

	local color = palette["colors"]["open"]

	fillImage(dungeon, image, color, canvas)
	openCells(dungeon, image, canvas)

	love.graphics.setCanvas()

	return canvas
end
