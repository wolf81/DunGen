require 'src/utils'

local Renderer = require 'src/renderer'
local Generator = require 'src/generator'

local function generatorDefaults()
	return {
		["seed"] = love.timer.getTime(),
		["dungeon_size"] = "medium",
		["dungeon_layout"] = "square",
		["doors"] = "standard",
		["room_size"] = "medium",
		["room_layout"] = "scattered", 	-- sparse|scattered|dense
		["corridor_layout"] = "Bent",
		["remove_deadends"] = "some",	-- none|some|all
		["add_stairs"] = "yes", 		-- stair count
	}
end

local function rendererDefaults()
	return {
		["map_style"] = "standard", 	-- standard|classic|graph
		["cell_size"] = 20, 			-- pixels
		["grid"] = "square", 			-- none|square|hex|vex
		["debug"] = false,
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