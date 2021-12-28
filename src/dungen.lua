require 'src/utils'

local Renderer = require 'src/renderer'
--local Generator = require 'src/generator'
local GeneratorBSP = require 'src/generators/generator_bsp'

local function generatorDefaults()
	return {
		["seed"] = love.timer.getTime(),
		--^ number
		["dungeon_size"] 		= "medium",
		--^ fine|dimin|tiny|small|medium|large|huge|gargant|colossal
		["dungeon_layout"] 		= "square",
		--^ square|rectangle|box|cross|dagger|saltire|keep|hexagon|round
		["doors"] 				= "standard",
		--^ none|basic|secure|standard|deathtrap
		["room_size"] 			= "medium",
		--^ small|medium|large|huge|gargant|colossal
		["room_layout"] 		= "scattered", 	
		--^ sparse|scattered|dense
		["corridor_layout"] 	= "errant",	
		--^ labyrinth|errant|straight
		["remove_deadends"] 	= "some",	
		--^ none|some|all
		["add_stairs"] 			= "yes", 		
		--^ no|yes|many
	}
end

local function rendererDefaults()
	return {
		["map_style"] 			= "classic", 	
		--^ standard|classic|graph
		["cell_size"] 			= 20, 			
		--^ number (pixels)
		["grid"] 				= "square", 			
		--^ none|square|hex|vex
		["debug"] 				= false,
		--^ true|false
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

	return GeneratorBSP.generate(100, 100)
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