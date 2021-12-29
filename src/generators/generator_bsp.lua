local Point = require 'src/utils/point'
local Container = require 'src/utils/container'
local BinTree = require 'src/utils/bin_tree'
local Room = require 'src/utils/room'
local Dungeon = require 'src/dungeon'
local Config = require 'src/config'

local MIN_RATIO = 0.35

local function random_split(container)
	local r1, r2 = nil, nil

	if math.random(0, 1) == 0 then
		r1 = Container(
			container.x, 
			container.y, 
			math.random(1, container.w), 
			container.h
		)
		r2 = Container(
			container.x + r1.w, 
			container.y, 
			container.w - r1.w, 
			container.h
		)

		local r1_w_ratio = r1.w / r1.h
		local r2_w_ratio = r2.w / r2.h
		if r1_w_ratio < MIN_RATIO or r2_w_ratio < MIN_RATIO then
			return random_split(container)
		end
	else
		r1 = Container(
			container.x, 
			container.y, 
			container.w,
			math.random(1, container.h)
		)
		r2 = Container(
			container.x, 
			container.y + r1.h, 
			container.w, 
			container.h - r1.h
		)

		local r1_h_ratio = r1.h / r1.w
		local r2_h_ratio = r2.h / r2.w
		if r1_h_ratio < MIN_RATIO or r2_h_ratio < MIN_RATIO then
			return random_split(container)		
		end
	end

	return r1, r2
end

local function split(container, iter)
	local root = BinTree(container)

	if iter > 0 then
		local r1, r2 = random_split(container)
		root:setChildren(
			split(r1, iter - 1), 
			split(r2, iter - 1)
		)
	end

	return root
end

local function connect_rooms(dungeon, tree)
	local lchild, rchild = tree:children()
	if rchild == nil or rchild == nil then
		return
	end	

	local x1, x2 = lchild._leaf.center.x, rchild._leaf.center.x
	local y1, y2 = lchild._leaf.center.y, rchild._leaf.center.y

	if x1 ~= x2 then
		for x = x1, x2 do
			if dungeon["cell"][x][y1] ~= Flags.ROOM then
				dungeon["cell"][x][y1] = Flags.CORRIDOR
			end
		end		
	elseif y1 ~= y2 then
		for y = y1, y2 do
			if dungeon["cell"][x1][y] ~= Flags.ROOM then
				dungeon["cell"][x1][y] = Flags.CORRIDOR
			end
		end
	end

	connect_rooms(dungeon, lchild)
	connect_rooms(dungeon, rchild)
end

local function calc_room_size(dungeon_size, room_size)
	local size = room_size["size"]
	local radix = room_size["radix"]
	local max_room_size = math.floor(dungeon_size / 4)
	local room_size = math.min(max_room_size, size + radix)
	local n = dungeon_size
	local steps = 1

	while room_size < dungeon_size do
		room_size = room_size * 2
		steps = steps + 1
	end

	return steps
end

local function generate(options)
	local dungeon_size = Config.dungeon_size[options["dungeon_size"]]
	local room_size = calc_room_size(
		dungeon_size,
		Config.room_size[options["room_size"]]
	)
	local levels = 5 -- math.floor(dungeon_size / room_size)

	local main_container = Container(0, 0, dungeon_size, dungeon_size)
	local container_tree = split(main_container, room_size)

	local rooms = {}
	for _, leaf in ipairs(container_tree:leafs()) do
		rooms[#rooms + 1] = Room(leaf)
	end

	local dungeon = Dungeon(dungeon_size, dungeon_size, rooms)

	connect_rooms(dungeon, container_tree)

	return dungeon
end

return setmetatable({
	generate = generate
}, {})