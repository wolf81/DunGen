io.stdout:setvbuf('no') -- show debug output live in SublimeText console

require 'src/dungen'

local texture = nil

local function generate()
	local dungeon = DunGen.generate({ 
		--['seed'] = 0.32, 
		["dungeon_layout"] = "Cross",
		["cell_size"] = 15,
		--["room_layout"] = "Packed",
	})

	texture = DunGen.getTexture(dungeon)
end

function love.load(args)
	love.window.setTitle('DunGen')

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