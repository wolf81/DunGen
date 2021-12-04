io.stdout:setvbuf('no') -- show debug output live in SublimeText console

require 'src/dungen'

function love.load(args)
	love.window.setTitle('DunGen')

	DunGen.generate({ 
		['seed'] = 0.32, 
		["dungeon_layout"] = "Cross",
	})
end