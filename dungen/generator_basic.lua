local _PATH = (...):match("(.-)[^%.]+$") 

local Dungeon = require(_PATH .. ".dungeon")
local Room = require(_PATH .. ".room")
local Corridor = require(_PATH .. ".corridor")
local Config = require(_PATH .. ".config")
local Rect = require(_PATH .. ".rect")
local Point = require(_PATH .. ".point")
local Set = require(_PATH .. ".set")

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

local function add_stairs(dungeon, room)
	local p = room:random_point()
	dungeon:set_cell(p.x * 2 + 1, p.y * 2 + 1, "/")
end

local function add_doors(dungeon, feats)
	for i, feat in ipairs(feats) do
		if getmetatable(feat) == Room then
			local x1, x2 = feat.x * 2, (feat.x + feat.w) * 2
			local y1, y2 = feat.y * 2, (feat.y + feat.h) * 2

			for y = y1, y2 do
				if dungeon:cell(x1, y) == "." then
					dungeon:set_cell(x1, y, "+")
				end

				if dungeon:cell(x2, y) == "." then
					dungeon:set_cell(x2, y, "+")
				end
			end

			for x = x1, x2 do
				if dungeon:cell(x, y1) == "." then
					dungeon:set_cell(x, y1, "+")
				end

				if dungeon:cell(x, y2) == "." then
					dungeon:set_cell(x, y2, "+")
				end
			end
		end
	end
end

local function connect_features(dungeon, feat1, feat2)
	local p1 = feat1:random_point()
	local p2 = feat2:random_point()

	local mid_x = math.floor((p1.x + p2.x) / 2)
	local mid_y = math.floor((p1.y + p2.y) / 2)

	local points = Set()

	local step_y = p2.y >= p1.y and 1 or -1
	local step_x = p2.x >= p1.x and 1 or -1

	local doors = {}
	local add_door1 = getmetatable(feat1) == Room

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

		local step_x = p2.x > p1.x and 1 or -1
		local step_y = p2.y > p1.y and 1 or -1

		for x = p1.x * 2 + 1, p2.x * 2 + 1, step_x do
			for y = p1.y * 2 + 1, p2.y * 2 + 1, step_y do
				dungeon:set_cell(x, y, ".")
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
				dungeon:set_cell(x, y, ".")
			end
		end
	end		
end

local function dig_room(dungeon, room)
	local x1 = room.x * 2 + 1
	local x2 = (room.x + room.w - 1) * 2 + 1
	local y1 = room.y * 2 + 1
	local y2 = (room.y + room.h - 1) * 2 + 1

	for x = x1 - 1, x2 + 1 do
		if dungeon:cell(x, y1 - 1) ~= "." then
			dungeon:set_cell(x, y1 - 1, "#")
		end

		if dungeon:cell(x, y2 + 1) ~= "." then
			dungeon:set_cell(x, y2 + 1, "#")
		end
	end

	for y = y1 - 1, y2 + 1 do
		if dungeon:cell(x1 - 1, y) ~= "." then
			dungeon:set_cell(x1 - 1, y, "#")	
		end

		if dungeon:cell(x2 + 1, y) ~= "." then
			dungeon:set_cell(x2 + 1, y, "#")	
		end
	end

	for x = x1, x2 do
		for y = y1, y2 do
			dungeon:set_cell(x, y, ".")
		end
	end
end

local function generate_feature(containers, feat_idx, connections)
	local is_root = connections == nil
	local feature = nil

	if containers[feat_idx].feature == nil then
		if is_root then 
			connections = {
				[1] = {}, [2] = {}, [3] = {},
				[4] = {}, [5] = {}, [6] = {},
				[7] = {}, [8] = {}, [9] = {},
			}

			feature = Room(containers[feat_idx])
		else
			local feat_type = math.random(3)
			if feat_type < 3 then
				feature = Room(containers[feat_idx])
			else
				feature = Corridor(containers[feat_idx])
			end
		end
		
		feature.adj_features = {}

		containers[feat_idx].feature = feature
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

		local adj_feature = generate_feature(containers, adj_feat_idx, connections)

		table.insert(feature.adj_features, adj_feature)

		::continue::
	end

	return feature
end

local function generate_features(containers)
	local room_idx = math.random(1, #containers)
	generate_feature(containers, room_idx)

	local features = {}
	for _, container in ipairs(containers) do
		if container.feature ~= nil then
			table.insert(features, container.feature)
		end
	end

	return features, room_idx
end

local function generate(options)
	local dungeon = Dungeon(options)

	-- create 9 rectangle containers for given width and height, as such:
	-- 	1, 2, 3
	-- 	4, 5, 6
	--	7, 8, 9
	local containers = {}

	local step_i = math.ceil(dungeon.n_i / 3)
	local step_j = math.ceil(dungeon.n_j / 3)

	for i = 0, dungeon.n_i, step_i do
		local w = step_i
		
		-- if the remainder is not equal to a third, then use the remainder
		if i + step_i > dungeon.n_i then
			w = dungeon.n_i - step_i * 2 - 1
		end

		for j = 0, dungeon.n_j, step_j do
			local h = step_j
			
			-- if the remainder is not equal to a third, then use the remainder
			if j + step_j > dungeon.n_j then
				h = dungeon.n_j - step_j * 2 - 1
			end

			-- create a rectangular area container
			containers[#containers + 1] = Rect(j, i, w, h)
		end
	end

	-- generate a feature in each container
	local features, root_idx = generate_features(containers)

	-- dig features and connect with corridors
	for _, feature in ipairs(features) do
		local mt = getmetatable(feature)
		if mt == Room then 
			dig_room(dungeon, feature)
		elseif mt == Corridor then 
			dig_corridor(dungeon, feature)
		else 
			error('unknown type: ', mt) 
		end

		for _, adj_feature in ipairs(feature.adj_features) do
			connect_features(dungeon, feature, adj_feature)
		end

		::continue::
	end

	local initial_room = containers[root_idx].feature
	add_stairs(dungeon, initial_room)	

	add_doors(dungeon, features)

	return dungeon
end

return setmetatable({
	generate = generate
}, {})