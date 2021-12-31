local Dungeon = require 'src/dungeon'
local Room = require 'src/features/room'
local Corridor = require 'src/features/corridor'
local Config = require 'src/config'
local Rect = require 'src/utils/rect'
local Point = require 'src/utils/point'
local Set = require 'src/utils/set'

--[[
	{ 1, 2, 3 },
	{ 4, 5, 6 },
	{ 7, 8, 9 },
]]
local adjacency_list = {
	[1] = { 2, 4 },
	[2] = { 1, 5, 3 },
	[3] = { 2, 6 },
	[4] = { 1, 5, 7 },
	[5] = { 2, 4, 6, 8 },
	[6] = { 3, 5, 9 },
	[7] = { 4, 8 },
	[8] = { 5, 7, 9 },
	[9] = { 6, 8 },
}

local function connect_features(dungeon, feat1, feat2)
	local p1 = feat1:random_point()
	local p2 = feat2:random_point()

	local mid_x = math.floor((p1.x + p2.x) / 2)
	local mid_y = math.floor((p1.y + p2.y) / 2)

	local points = Set()

	local step_y = p2.y >= p1.y and 1 or -1
	local step_x = p2.x >= p1.x and 1 or -1

	for y = p1.y, mid_y, step_y do
		points:add(Point(p1.x, y))
	end

	for x = p1.x, p2.x, step_x do
		points:add(Point(x, mid_y))
	end

	for y = mid_y, p2.y, step_y do
		points:add(Point(p2.x, y))		
	end

	for i = 1, points:size() - 1 do
		local p1 = points:get(i)
		local p2 = points:get(i + 1)

		step_x = p2.x > p1.x and 1 or -1
		step_y = p2.y > p1.y and 1 or -1

		for x = p1.x * 2 + 1, p2.x * 2 + 1, step_x do
			for y = p1.y * 2 + 1, p2.y * 2 + 1, step_y do
				dungeon:set_cell(x, y, Flags.CORRIDOR)
			end
		end
	end

end

local function dig_corridor(dungeon, corridor)
	local points = corridor:points()

	for i = 1, #points - 1 do
		local p1 = points[i]
		local p2 = points[i + 1]

		for x = p1.x * 2 + 1, p2.x * 2 + 1 do
			for y = p1.y * 2 + 1, p2.y * 2 + 1 do
				dungeon:set_cell(x, y, Flags.CORRIDOR)
			end
		end
	end		
end

local function dig_room(dungeon, room)
	local x1 = room.x * 2 + 1
	local x2 = (room.x + room.w - 1) * 2 + 1
	local y1 = room.y * 2 + 1
	local y2 = (room.y + room.h - 1) * 2 + 1

	for x = x1, x2 do
		for y = y1, y2 do
			dungeon:set_cell(x, y, Flags.ROOM)
		end
	end
end

local function generate_feature(dungeon, containers, feat_idx, connections)
	local is_root = connections == nil
	local feature = nil

	if containers[feat_idx].is_generated == nil then
		if is_root then 
			connections = {
				[1] = {}, [2] = {}, [3] = {},
				[4] = {}, [5] = {}, [6] = {},
				[7] = {}, [8] = {}, [9] = {},
			}

			feature = Room(containers[feat_idx])
			dig_room(dungeon, feature)		
		else
			local feat_type = math.random(3)
			if feat_type < 3 then
				feature = Room(containers[feat_idx])
				dig_room(dungeon, feature)
			else
				feature = Corridor(containers[feat_idx])
				dig_corridor(dungeon, feature)
			end
		end
		containers[feat_idx].is_generated = true
	end

	if feature == nil then return end

	local adj_feats = adjacency_list[feat_idx]
	local n_conns = math.random(1, #adj_feats)

	while #connections[feat_idx] < n_conns do
		local adj_feat_idx = adj_feats[math.random(#adj_feats)]

		for i, v in ipairs(connections[feat_idx]) do
			if v == adj_feat_idx then goto continue end
		end

		table.insert(connections[feat_idx], adj_feat_idx)
		table.insert(connections[adj_feat_idx], feat_idx)
		local next_feature = generate_feature(dungeon, containers, adj_feat_idx, connections)

		if next_feature ~= nil then
			connect_features(dungeon, feature, next_feature)
		end

		::continue::
	end

	return feature
end

local function generate_features(dungeon, containers)
	local rooms = {}
	local corridors = {}

	local room_idx = math.random(1, #containers)
	generate_feature(dungeon, containers, room_idx)

	return concat(rooms, corridors)
end

local function generate(options)
	local dungeon = Dungeon(options)

	local step_i = math.ceil(dungeon.n_i / 3)
	local step_j = math.ceil(dungeon.n_j / 3)

	local containers = {}

	for i = 0, dungeon.n_i, step_i do
		local w = step_i
		if i + step_i > dungeon.n_i then
			w = dungeon.n_i % step_i
		end

		for j = 0, dungeon.n_j, step_j do
			local h = step_j
			if j + step_j > dungeon.n_j then
				h = dungeon.n_j % step_j
			end

			containers[#containers + 1] = Rect(j, i, w, h)
		end
	end

	local features = generate_features(dungeon, containers)

	return dungeon
end

return setmetatable({
	generate = generate
}, {})