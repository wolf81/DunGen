-- LuaJIT 2.1 required
local ffi = require'ffi'

require 'src/flags'

Generator = {}

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
        ["walled"]    = {{1,-1},{0,-1},{-1,-1},{-1,0},{-1,1},{0,1},{1,1}},
        ["corridor"]  = {{0,0},{1,0},{2,0}},
        ["stair"]     = {0,0},
        ["next"]      = {1,0},
    },
    ["south"] = {
        ["walled"]    = {{-1,-1},{0,-1},{1,-1},{1,0},{1,1},{0,1},{-1,1}},
        ["corridor"]  = {{0,0},{-1,0},{-2,0}},
        ["stair"]     = {0,0},
        ["next"]      = {-1,0},
    },
    ["west"] = {
        ["walled"]    = {{-1,1},{-1,0},{-1,-1},{0,-1},{1,-1},{1,0},{1,1}},
        ["corridor"]  = {{0,0},{0,1},{0,2}},
        ["stair"]     = {0,0},
        ["next"]      = {0,1},
    },
    ["east"] = {
        ["walled"]    = {{-1,-1},{-1,0},{-1,1},{0,1},{1,1},{1,0},{1,-1}},
        ["corridor"]  = {{0,0},{0,-1},{0,-2}},
        ["stair"]     = {0,0},
        ["next"]      = {0,-1},
    },
};

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
	}
}

local corridor_layout = {
	["Labyrinth"] 	= 0,
	["Bent"] 		= 50,
	["Straight"] 	= 100,	
}

local connect = nil

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
	elseif dungeon_layout[mask] ~= nil then
		maskCells(dungeon, dungeon_layout[mask])		
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

	local hit_list = getKeys(hit)
	local room_id = nil

	if #hit_list == 0 then
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
	local n_opens = flumph + love.math.random(flumph)

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

			goto continue
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

        local door_type = getDoorType()
        local door = {
        	["row"] = door_r,
        	["col"] = door_c,
        }

        if door_type == Flags.ARCH then
        	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], Flags.ARCH)
        	door["key"] = "arch"
        	door["type"] = "Archway"
        elseif door_type == Flags.DOOR then
        	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], Flags.DOOR)
        	door["key"] = "open"
        	door["type"] = "Unlocked Door"
        	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], bit.lshift(string.byte('o'), 24))
            -- $cell->[$door_r][$door_c] |= (ord('o') << 24);
        elseif door_type == Flags.LOCKED then
        	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], Flags.LOCKED)
        	door["key"] = "lock"
        	door["type"] = "Locked Door"
        	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], bit.lshift(string.byte('x'), 24))
            -- $cell->[$door_r][$door_c] |= (ord('x') << 24);
        elseif door_type == Flags.TRAPPED then
        	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], Flags.TRAPPED)
        	door["key"] = "trap"
        	door["type"] = "Trapped Door"
        	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], bit.lshift(string.byte('t'), 24))
            -- $cell->[$door_r][$door_c] |= (ord('t') << 24);
        elseif door_type == Flags.SECRET then
        	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], Flags.SECRET)
        	door["key"] = "secret"
        	door["type"] = "Secret Door"
        	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], bit.lshift(string.byte('s'), 24))
            -- $cell->[$door_r][$door_c] |= (ord('s') << 24);
        elseif door_type == Flags.PORTC then	        	
        	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], Flags.PORTC)
        	door["key"] = "portc"
        	door["type"] = "Portcullis"
        	cell[door_r][door_c] = bit.bor(cell[door_r][door_c], bit.lshift(string.byte('#'), 24))
            -- $cell->[$door_r][$door_c] |= (ord('#') << 24);
        end

        if out_id ~= nil then door["out_id"] = out_id end

        table.insert(room["door"][open_dir], door)

        ::continue::
	end
end

--[[
sub fix_doors {
    my ($dungeon) = @_;
    my $cell = $dungeon->{'cell'};
    my $fixed;
    
    my $room; foreach $room (@{ $dungeon->{'room'} }) {
        my $dir; foreach $dir (sort keys %{ $room->{'door'} }) {
            my ($door,@shiny); foreach $door (@{ $room->{'door'}{$dir} }) {
                my $door_r = $door->{'row'};
                my $door_c = $door->{'col'};
                my $door_cell = $cell->[$door_r][$door_c];
                next unless ($door_cell & $OPENSPACE);
                
                if ($fixed->[$door_r][$door_c]) {
                    push(@shiny,$door);
                } else {
                    my $out_id; if ($out_id = $door->{'out_id'}) {
                        my $out_dir = $opposite->{$dir};
                        push(@{ $dungeon->{'room'}[$out_id]{'door'}{$out_dir} },$door);
                    }
                    push(@shiny,$door);
                    $fixed->[$door_r][$door_c] = 1;
                }
            }
            if (@shiny) {
                $room->{'door'}{$dir} = \@shiny;
                push(@{ $dungeon->{'door'} },@shiny);
            } else {
                delete $room->{'door'}{$dir};
            }
        }
    }
    return $dungeon;
}
]]

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

				if bit.band(door_cell, Flags.OPENSPACE) ~= 0 then goto continue end

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

--[[
    my ($dungeon) = @_;
    
    if ($dungeon->{'remove_deadends'}) {
        $dungeon = &remove_deadends($dungeon);
    }
    $dungeon = &fix_doors($dungeon);
    $dungeon = &empty_blocks($dungeon);
    
    return $dungeon;
]]
local function cleanDungeon(dungeon)
	--[[
	if dungeon["remove_deadends"] ~= nil then
		removeDeadends(dungeon)
	end
	--]]

	fixDoors(dungeon)
	--emptyBlocks(dungeon)
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

--[[
sub label_rooms {
    my ($dungeon) = @_;
    my $cell = $dungeon->{'cell'};
    
    my $id; for ($id = 1; $id <= $dungeon->{'n_rooms'}; $id++) {
        my $room = $dungeon->{'room'}[$id];
        my $label = "$room->{'id'}";
        my $len = length($label);
        my $label_r = int(($room->{'north'} + $room->{'south'}) / 2);
        my $label_c = int(($room->{'west'} + $room->{'east'} - $len) / 2) + 1;
        
        my $c; for ($c = 0; $c < $len; $c++) {
            my $char = substr($label,$c,1);
            $cell->[$label_r][$label_c + $c] |= (ord($char) << 24);
        }
    }
    return $dungeon;
}
]]

local function labelRooms(dungeon)
	local cell = dungeon["cell"]

	for id = 1, dungeon["n_rooms"] do
		local room = dungeon["room"][id]
		local label = room["id"]
		local len = string.len(label)
		local label_r = math.floor((room["north"] + room["south"]) / 2)
		local label_c = math.floor((room["west"] + room["east"] - len) / 2) + 1

		for c = 0, len - 1 do
			local char = string.sub(label, c, 1)
			local mask = bit.lshift(string.byte(char), 24)
			cell[label_r][label_c + c] = bit.bor(cell[label_r][label_c + c], mask)
		end
	end
end

local function corridorLayout(layout)
	-- body
end

--[[
sub tunnel_dirs {
    my ($dungeon,$last_dir) = @_;
    my $p = $corridor_layout->{$dungeon->{'corridor_layout'}};
    my @dirs = &shuffle(@dj_dirs);
    
    if ($last_dir && $p) {
        unshift(@dirs,$last_dir) if (int(rand(100)) < $p);
    }
    return @dirs;
}
]]

local function tunnelDirs(dungeon, layout, last_dir)
	local p = corridor_layout[layout]

	-- TODO: what does it matter if we use sorted table dj_dirs while
	-- afterwards shuffling as in original code?
	local keys = getKeys(dj)
	local dirs = shuffle(keys)

	if last_dir ~= nil and p ~= nil then
		if love.math.random(100) < p then
			table.insert(dirs, last_dir)
		end
	end

	return dirs
end

--[[
sub delve_tunnel {
    my ($dungeon,$this_r,$this_c,$next_r,$next_c) = @_;
    my $cell = $dungeon->{'cell'};
    my ($r1,$r2) = sort { $a <=> $b } ($this_r,$next_r);
    my ($c1,$c2) = sort { $a <=> $b } ($this_c,$next_c);
    
    my $r; for ($r = $r1; $r <= $r2; $r++) {
        my $c; for ($c = $c1; $c <= $c2; $c++) {
            $cell->[$r][$c] &= ~ $ENTRANCE;
            $cell->[$r][$c] |= $CORRIDOR;
        }
    }
    return 1;
}
]]

local function delveTunnel(dungeon, this_r, this_c, next_r, next_c)
	local cell = dungeon["cell"]

	local tbl_r, tbl_c = { this_r, next_r }, { this_c, next_c }
	
	table.sort(tbl_r)
	local r1, r2 = unpack(tbl_r)

	table.sort(tbl_c)
	local c1, c2 = unpack(tbl_c)

	for r = r1, r2, 1 do
		for c = c1, c2, 1 do
			cell[r][c] = bit.band(cell[r][c], bit.bnot(Flags.ENTRANCE))
			cell[r][c] = bit.bor(cell[r][c], Flags.CORRIDOR)
		end
	end

	return true
end

--[[
sub sound_tunnel {
    my ($dungeon,$mid_r,$mid_c,$next_r,$next_c) = @_;
    return 0 if ($next_r < 0 || $next_r > $dungeon->{'n_rows'});
    return 0 if ($next_c < 0 || $next_c > $dungeon->{'n_cols'});
    my $cell = $dungeon->{'cell'};
    my ($r1,$r2) = sort { $a <=> $b } ($mid_r,$next_r);
    my ($c1,$c2) = sort { $a <=> $b } ($mid_c,$next_c);
    
    my $r; for ($r = $r1; $r <= $r2; $r++) {
        my $c; for ($c = $c1; $c <= $c2; $c++) {
            return 0 if ($cell->[$r][$c] & $BLOCK_CORR);
        }
    }
    return 1;
}
]]

local function soundTunnel(dungeon, mid_r, mid_c, next_r, next_c)
	if next_r < 0 or next_r > dungeon["n_rows"] then return false end
	if next_c < 0 or next_c > dungeon["n_cols"] then return false end

	local cell = dungeon["cell"]
	local tbl_r, tbl_c = { mid_r, next_r }, { mid_c, next_c }

	table.sort(tbl_r)
	local r1, r2 = unpack(tbl_r)

	table.sort(tbl_c)
	local c1, c2 = unpack(tbl_c)

	for r = r1, r2, 1 do
		for c = c1, c2, 1 do
			if bit.band(cell[r][c], Flags.BLOCK_CORR) ~= 0 then return false end
		end
	end	

	return true
end

--[[
sub open_tunnel {
    my ($dungeon,$i,$j,$dir) = @_;
    my $this_r = ($i * 2) + 1;
    my $this_c = ($j * 2) + 1;
    my $next_r = (($i + $di->{$dir}) * 2) + 1;
    my $next_c = (($j + $dj->{$dir}) * 2) + 1;
    my $mid_r = ($this_r + $next_r) / 2;
    my $mid_c = ($this_c + $next_c) / 2;
    
    if (&sound_tunnel($dungeon,$mid_r,$mid_c,$next_r,$next_c)) {
        return &delve_tunnel($dungeon,$this_r,$this_c,$next_r,$next_c);
    } else {
        return 0;
    }
}
]]

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

--[[
sub tunnel {
    my ($dungeon,$i,$j,$last_dir) = @_;
    my @dirs = &tunnel_dirs($dungeon,$last_dir);
    
    my $dir; foreach $dir (@dirs) {
        if (&open_tunnel($dungeon,$i,$j,$dir)) {
            my $next_i = $i + $di->{$dir};
            my $next_j = $j + $dj->{$dir};
            
            $dungeon = &tunnel($dungeon,$next_i,$next_j,$dir);
        }
    }
    return $dungeon;
}
]]

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

--[[
sub corridors {
    my ($dungeon) = @_;
    my $cell = $dungeon->{'cell'};
    
    my $i; for ($i = 1; $i < $dungeon->{'n_i'}; $i++) {
        my $r = ($i * 2) + 1;
        my $j; for ($j = 1; $j < $dungeon->{'n_j'}; $j++) {
            my $c = ($j * 2) + 1;
            
            next if ($cell->[$r][$c] & $CORRIDOR);
            $dungeon = &tunnel($dungeon,$i,$j);
        }
    }
    return $dungeon;
}
]]
local function corridors(dungeon, layout)
	local cell = dungeon["cell"]

	for i = 1, dungeon["n_i"] - 1 do
		local r = i * 2 + 1
		for j = 1, dungeon["n_j"] - 1 do
			local c = j * 2 + 1

			if bit.band(cell[r][c], Flags.CORRIDOR) ~= 0 then goto continue end

			tunnel(dungeon, layout, i, j, last_dir)

			::continue::
		end
	end
end

--[[
sub check_tunnel {
    my ($cell,$r,$c,$check) = @_;
    my $list;
    
    if ($list = $check->{'corridor'}) {
        my $p; foreach $p (@{ $list }) {
            return 0 unless ($cell->[$r+$p[0][$c+$p[1] == $CORRIDOR);
        }
    }
    if ($list = $check->{'walled'}) {
        my $p; foreach $p (@{ $list }) {
            return 0 if ($cell->[$r+$p[0][$c+$p[1] & $OPENSPACE);
        }
    }
    return 1;
}
]]

local function checkTunnel(cell, r, c, check)
	local list = check["corridor"]
	if list ~= nil then
		for _, p in ipairs(list) do
			if cell[r + p[1]][c + p[2]] ~= Flags.CORRIDOR then
				return false
			end
		end
	end

	list = check["walled"]
	if list ~= nil then
		for _, p in ipairs(list) do
			if bit.band(cell[r + p[1]][c + p[2]], Flags.OPENSPACE) ~= 0 then
				return false
			end			
		end
	end

	return true
end

--[[
sub stair_ends {
    my ($dungeon) = @_;
    my $cell = $dungeon->{'cell'};
    my @list;
    
    my $i; ROW: for ($i = 0; $i < $dungeon->{'n_i'}; $i++) {
        my $r = ($i * 2) + 1;
        my $j; COL: for ($j = 0; $j < $dungeon->{'n_j'}; $j++) {
            my $c = ($j * 2) + 1;
            
            next unless ($cell->[$r][$c] == $CORRIDOR);
            next if ($cell->[$r][$c] & $STAIRS);
            
            my $dir; foreach $dir (keys %{ $stair_end }) {
                if (&check_tunnel($cell,$r,$c,$stair_end->{$dir})) {
                    my $end = { 'row' => $r, 'col' => $c };
                    my $n = $stair_end->{$dir}{'next'};
                    $end->{'next_row'} = $end->{'row'} + $n->[0];
                    $end->{'next_col'} = $end->{'col'} + $n->[1];
                    
                    push(@list,$end); next COL;
                }
            }
        }
    }
    return @list;
}
]]

local function stairEnds(dungeon)
	local cell = dungeon["cell"]
	local list = {}

	for i = 0, dungeon["n_i"] - 1 do
		local r = (i * 2) + 1
		for j = 0, dungeon["n_j"] - 1 do
			local c = (j * 2) + 1

			if cell[r][c] ~= Flags.CORRIDOR then goto continue end
			if bit.band(cell[r][c], Flags.STAIRS) ~= 0 then goto continue end

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

--[[
sub emplace_stairs {
    my ($dungeon) = @_;
    my $n = $dungeon->{'add_stairs'};
    return $dungeon unless ($n > 0);
    my @list = &stair_ends($dungeon);
    return $dungeon unless (@list);
    my $cell = $dungeon->{'cell'};
    
    my $i; for ($i = 0; $i < $n; $i++) {
        my $stair = splice(@list,int(rand(@list)),1);
        last unless ($stair);
        my $r = $stair->{'row'};
        my $c = $stair->{'col'};
        my $type = ($i < 2) ? $i : int(rand(2));
        
        if ($type == 0) {
            $cell->[$r][$c] |= $STAIR_DN;
            $cell->[$r][$c] |= (ord('d') << 24);
            $stair->{'key'} = 'down';
        } else {
            $cell->[$r][$c] |= $STAIR_UP;
            $cell->[$r][$c] |= (ord('u') << 24);
            $stair->{'key'} = 'up';
        }
        push(@{ $dungeon->{'stair'} },$stair);
    }
    return $dungeon;
}
]]

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
		local s_type = i < 2 and i or love.math.random(2)

		if s_type == 0 then
			cell[r][c] = bit.bor(cell[r][c], Flags.STAIR_DN)
			cell[r][c] = bit.bor(cell[r][c], bit.lshift(string.byte("d"), 24))
			stair["key"] = "down"
		else
			cell[r][c] = bit.bor(cell[r][c], Flags.STAIR_UP)
			cell[r][c] = bit.bor(cell[r][c], bit.lshift(string.byte("u"), 24))
			stair["key"] = "up"
		end

		table.insert(dungeon["stair"], stair)
	end
end

function Generator.generate(options)
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
	dungeon["door"] = {}
	dungeon["stair"] = {}

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
	labelRooms(dungeon)

	local layout = options["corridor_layout"]
	corridors(dungeon, layout)

	local n_stairs = options["add_stairs"]
	emplaceStairs(dungeon, n_stairs)

	cleanDungeon(dungeon)

	for k, v in ipairs(dungeon["room"]) do
		for k2, v2 in pairs(v) do
			print(k2, v2)
		end
		print()
	end

	return dungeon
end