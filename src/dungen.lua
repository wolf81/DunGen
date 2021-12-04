DunGen = {}

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

local function merge(table1, table2)
	for k, v in pairs(table2) do
		assert(table1[k] ~= nil, "invalid key: " .. k)

		table1[k] = v
	end 

	return table1
end

local function getOpts()
	return {
		["seed"] = love.math.random(),
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

local function maskCells(dungeon, mask)
	local r_x = #mask * 1.0 / (dungeon["n_rows"])
	local c_x = #mask[0] * 1.0 / (dungeon["n_cols"])
	local cell = dungeon["cell"]

	for r = 0, dungeon["n_rows"] do
		for c = 0, dungeon["n_cols"] do
			cell[r][c] = mask[math.floor(r * r_x + 0.5)][math.floor(c * c_x + 0.5)] == 1 and 0 or 1
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
			cell[r][c] = d > center_c and 1 or 0
		end
	end
end

local function initCells(dungeon, mask)
	dungeon["cell"] = {}

	for r = 0, dungeon["n_rows"] do
		dungeon["cell"][r] = {}
		for c = 0, dungeon["n_cols"] do
			dungeon["cell"][r][c] = 0
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
			if cell[r][c] == 1 then
				return { ["blocked"] = true }
			end

			-- TODO: check room bitmask value instead
			if cell[r][c] == 2 then
				-- update hit count for the room
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
			local a = dungeon["n_j"] - base - proto["j"]
			a = math.max(a, 0)
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

--[[
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
--]]
end

local function allocRooms(dungeon, roomMax)
	local dungeonArea = dungeon["n_cols"] * dungeon["n_rows"]
	local roomArea = roomMax * roomMax
	local nRooms = math.floor(dungeonArea / roomArea)

	return nRooms
end

local function packRooms(dungeon)
	local cell = dungeon["cell"]

	for i = 0, dungeon["n_i"] - 1 do
		local r = i * 2 + 1
		for j = 0, dungeon["n_j"] - 1 do
			local c = j * 2 + 1

			local hasRoom = cell[r][c] == 2
			local shouldSkip = (i == 0 or j == 0) and love.math.random(0, 1) == 1

			if not hasRoom and not shouldSkip then
				local proto = { 
					["i"] = i, 
					["j"] = j 
				}
				emplaceRoom(dungeon, proto)
			end
		end
	end
end

local function scatterRooms(dungeon, roomMax)
	local nRooms = allocRooms(dungeon, roomMax)

	for i = 0, nRooms - 1 do
		emplaceRoom(dungeon)
	end
end

local function emplaceRooms(dungeon, roomLayout, roomMax)
	if roomLayout == 'Packed' then
		packRooms(dungeon, roomMax)
	else 
		scatterRooms(dungeon, roomMax)
	end	
end

function DunGen.generate(options)
	local options = merge(getOpts(), options or {})

	print('\ngenerate dungeon:')
	for k, v in pairs(options) do
		print(' ' .. k, v)
	end

	local dungeon = {}

	dungeon["n_i"] = math.floor(options["n_rows"] / 2)
	dungeon["n_j"] = math.floor(options["n_cols"] / 2)
	dungeon["n_rows"] = dungeon["n_i"] * 2
	dungeon["n_cols"] = dungeon["n_j"] * 2
	dungeon["max_row"] = dungeon["n_rows"] - 1
	dungeon["max_col"] = dungeon["n_cols"] - 1
	dungeon["rooms"] = 0

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

	local s = ''
	for r = 0, dungeon["n_rows"] do
		s = s .. '\n'
		for c = 0, dungeon["n_cols"] do
			s = s .. dungeon["cell"][r][c]
		end
	end
	print(s)
end
