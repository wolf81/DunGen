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

--[[
    my ($dungeon,$mask) = @_;
    my $r_x = (scalar @{ $mask } * 1.0 / ($dungeon->{'n_rows'} + 1));
    my $c_x = (scalar @{ $mask->[0] } * 1.0 / ($dungeon->{'n_cols'} + 1));
    my $cell = $dungeon->{'cell'};
    
    my $r; for ($r = 0; $r <= $dungeon->{'n_rows'}; $r++) {
        my $c; for ($c = 0; $c <= $dungeon->{'n_cols'}; $c++) {
            $cell->[$r][$c] = $BLOCKED unless ($mask->[$r * $r_x][$c * $c_x]);
        }
    }
    return $dungeon;
]]

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

local function packRooms(dungeon)
	-- body
end

local function scatterRooms(dungeon)
	-- body
end

local function emplaceRooms(dungeon, roomLayout)
	if roomLayout == 'Packed' then
		packRooms(dungeon)
	else 
		scatterRooms(dungeon)
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

	local roomLayout = options["room_layout"]
	emplaceRooms(dungeon, roomLayout)

	local s = ''
	for r = 0, dungeon["n_rows"] do
		s = s .. '\n'
		for c = 0, dungeon["n_cols"] do
			s = s .. dungeon["cell"][r][c]
		end
	end
	print(s)
end
