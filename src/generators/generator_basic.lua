local Dungeon = require 'src/dungeon'
local Config = require 'src/config'
local Rect = require 'src/utils/rect'

local function sign(number)
	return (number > 0 and 1) or (number < 0 and -1) or 0
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
			print(containers[#containers])
		end
	end

	return dungeon
end

return setmetatable({
	generate = generate
}, {})