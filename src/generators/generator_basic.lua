local Dungeon = require 'src/dungeon'
local Room = require 'src/utils/room'
local Config = require 'src/config'
local Container = require 'src/utils/container'
local Point = require 'src/utils/point'

local function sign(number)
	return (number > 0 and 1) or (number < 0 and -1) or 0
end

local function generate_corridor(room1, room2)
	local x1, y1 = room1.x + math.random(room1.w - 1), room1.y + math.random(room1.h - 1)
	local x2, y2 = room2.x + math.random(room2.w - 1), room2.y + math.random(room2.h - 1)
	local dir = math.random(0, 1) -- horizontal or vertical
	local mid = (dir == 0) and math.floor((x1 + x2) / 2) or math.floor((y1 + y2) / 2)

	local points = {}

	if dir == 0 then		
		local step = mid > x1 and 1 or -1
		for x = x1, mid, step do
			points[#points + 1] = Point(x, y1)
		end

		step = y2 > y1 and 1 or -1
		for y = y1, y2, step do
			points[#points + 1] = Point(mid, y)			
		end

		step = x2 > mid and 1 or -1
		for x = mid, x2, step do
			points[#points + 1] = Point(x, y2)
		end
	else
		local step = mid > y1 and 1 or -1
		for y = y1, mid, step do
			points[#points + 1] = Point(x1, y)
		end

		step = x2 > x1 and 1 or -1
		for x = x1, x2, step do
			points[#points + 1] = Point(x, mid)			
		end

		step = y2 > mid and 1 or -1
		for y = mid, y2, step do
			points[#points + 1] = Point(x2, y)
		end
	end

	return points
end

local function connect_rooms(rooms)
	local corridors = {}

	rooms = shuffle(rooms)

	for i = 1, #rooms - 1 do
		local room1 = rooms[i]
		local room2 = rooms[i + 1]
		corridors[#corridors + 1] = generate_corridor(room1, room2)
	end

	return corridors
end

local function generate_rooms(dungeon_size)
	local rooms = {}

	-- create 9 rectangular areas for rooms
	local step = math.ceil(dungeon_size / 3)
	for y = 0, dungeon_size - 1, step do
		for x = 0, dungeon_size - 1, step do
			local container = Container(x, y, step, step)
			rooms[#rooms + 1] = Room(container)
		end
	end

	return rooms
end

local function generate(options)
	local dungeon_size = Config.dungeon_size[options["dungeon_size"]]
	local room_size = Config.room_size[options["room_size"]]

	local rooms = {}
	local dungeon = Dungeon(dungeon_size, dungeon_size, rooms)

	local rooms = generate_rooms(dungeon_size)
	local corridors = connect_rooms(rooms)

	for _, corridor in ipairs(corridors) do
		for _, point in ipairs(corridor) do
			dungeon:set_cell(point.x, point.y, Flags.CORRIDOR)
		end
	end

	for idx, room in ipairs(rooms) do
		for x = room.x, (room.x + room.w - 1) do
			for y = room.y, (room.y + room.h - 1) do
				local value = bit.bor(Flags.ROOM, bit.lshift(idx, 6))
				dungeon:set_cell(x, y, value)
			end
		end
	end

	return dungeon
end

return setmetatable({
	generate = generate
}, {})