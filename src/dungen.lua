require 'src/utils'

local Renderer = require 'src/renderer'
local Generator = require 'src/generator'

local function generatorDefaults()
	return {
		["seed"] = love.timer.getTime(),
		["n_rows"] = 39, 				-- must be an odd number
		["n_cols"] = 39, 				-- must be an odd number
		["dungeon_layout"] = 'None',
		["room_min"] = 3, 				-- minimum room size
		["room_max"] = 9, 				-- maximum room size
		["room_layout"] = 'Scattered', 	-- Packed, Scattered
		["corridor_layout"] = "Bent",
		["remove_deadends"] = 50, 		-- percentage
		["add_stairs"] = 2, 			-- number of stairs
	}
end

local function rendererDefaults()
	return {
		["map_style"] = "standard", 	-- standard|classic|graph
		["cell_size"] = 18, 			-- size in pixels		
		["grid"] = "square" 			-- none|square|hex|vex
	}
end

local function generate(options)
	local options = merge(generatorDefaults(), options or {})

	--[[
	print('\ngenerate:')
	for k, v in pairs(options) do
		print(' ' .. k, v)
	end
	--]]

	return Generator.generate(options)
end

local function render(dungeon, options)
	local options = merge(rendererDefaults(), options or {})

	--[[
	print('\nrender:')
	for k, v in pairs(options) do
		print(' ' .. k, v)
	end
	--]]

	return Renderer.render(dungeon, options)
end

-- the module
return setmetatable({
	generate = generate,
	render = render,
	Flags = Flags,
}, {})