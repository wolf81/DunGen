local Dungeon = require 'src/dungeon'
local Config = require 'src/config'
local Rect = require 'src/utils/rect'

local function sign(number)
	return (number > 0 and 1) or (number < 0 and -1) or 0
end

local function generate(options)
	local dungeon_size = Config.dungeon_size[options["dungeon_size"]]

	local dungeon = Dungeon(dungeon_size, dungeon_size)

	return dungeon
end

return setmetatable({
	generate = generate
}, {})