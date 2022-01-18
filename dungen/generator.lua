local _PATH = (...):match("(.-)[^%.]+$") 

local tablex = require(_PATH .. ".tablex")

--local Generator = require 'src/generator'
local Generator = require(_PATH .. ".generator_basic")

local function generatorDefaults()
	return {
		["seed"] = love.timer.getTime(),
		--^ number
		["dungeon_size"] 		= "medium",
		--^ fine|dimin|tiny|small|medium|large|huge|gargant|colossal
		--["dungeon_layout"] 		= "square",
		--^ square|rectangle|box|cross|dagger|saltire|keep|hexagon|round
		--["doors"] 				= "standard",
		--^ none|basic|secure|standard|deathtrap
		--["room_size"] 			= "medium",
		--^ small|medium|large|huge|gargant|colossal
		--["room_layout"] 		= "scattered", 	
		--^ sparse|scattered|dense
		--["corridor_layout"] 	= "errant",	
		--^ labyrinth|errant|straight
		--["remove_deadends"] 	= "some",	
		--^ none|some|all
		--["add_stairs"] 			= "yes", 		
		--^ no|yes|many
	}
end

local function generate(options)
	local options = tablex.merge(generatorDefaults(), options or {})

	--[[
	print('\ngenerate:')
	for k, v in pairs(options) do
		print(' ' .. k, v)
	end
	--]]

	return Generator.generate(options)
end

-- the module
return setmetatable({
	generate = generate,
	render = render,
	Flags = Flags,
}, {})