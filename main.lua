io.stdout:setvbuf('no') -- show debug output live in SublimeText console

local DunGen = require 'src/dungen'

local texture = nil

local function generate()
	local dungeon = DunGen.generate({ 
		--['seed'] = 0.32, 
		["dungeon_layout"] = "keep",
		--["add_stairs"] = "yes",
		--["doors"] = "basic",
		["room_layout"] = "sparse",
		["dungeon_size"] = "medium",
		["room_size"] = "small",
		["corridor_layout"] = "straight",
		--["remove_deadends"] = "none",
	})

	texture = DunGen.render(dungeon, { 
		["cell_size"] = 12, 
		["grid"] = "square",
	})
end

function love.load(args)
	love.window.setTitle('DunGen')
	
	_ = love.window.setMode(1024, 720)

	generate()
end

function love.draw()
	love.graphics.draw(texture)
end

function love.keypressed(key, code)
	if key == "g" then
		generate()
	end

	if key == "q" then
		love.event.quit()
	end
end