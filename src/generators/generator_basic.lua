local Dungeon = require 'src/dungeon'
local Room = require 'src/features/room'
local Config = require 'src/config'
local Rect = require 'src/utils/rect'

local function sign(number)
	return (number > 0 and 1) or (number < 0 and -1) or 0
end

local function generate_features(dungeon, containers)
	local rooms = {}
	local corridors = {}

	for _, container in ipairs(containers) do
		local v = math.random(6)
		if v < 4 then
			local room = Room(container)
			print(room)
			rooms[#rooms + 1] = room

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
	end

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

			containers[#containers + 1] = Rect(i, j, w, h)
		end
	end

	local features = generate_features(dungeon, containers)

	return dungeon
end

return setmetatable({
	generate = generate
}, {})