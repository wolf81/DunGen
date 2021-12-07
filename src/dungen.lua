require 'src/utils'
require 'src/renderer'
require 'src/generator'

local function defaults()
	return {
		["seed"] = love.timer.getTime(),
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

local function generate(options)
	local options = merge(defaults(), options or {})

	print('\ngenerate dungeon:')
	for k, v in pairs(options) do
		print(' ' .. k, v)
	end

	return Generator.generate(options)
end

local function render(dungeon)
	return Renderer.render(dungeon)
end

return setmetatable({
	generate = generate,
	render = render,
}, {})