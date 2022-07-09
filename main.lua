require 'src.utils'
require 'src.config'

io.stdout:setvbuf('no') -- show debug output live in SublimeText console

local DunGen = require 'src.dungen'

local texture, info_texts, pointer_texts = nil, {}, {}
local window_w, window_h = 1024, 720
local dungeon = nil

local renderOptions = {
	cell_size = 12,
	grid = square,
	--debug = true,
}

local function getRandomKey(config_tbl)
	local keys = getKeys(config_tbl)
	return keys[math.random(#keys)]
end

local function generate()
	local dungeonOptions = {
		seed = 'The unnamed horror',
		dungeon_size = getRandomKey(DungeonSize),
		dungeon_layout = getRandomKey(DungeonLayout),
		doors = getRandomKey(Doors),
		room_size = getRandomKey(RoomSize),
		room_layout = getRandomKey(RoomLayout),
		corridor_layout = getRandomKey(CorridorLayout),
		remove_deadends = getRandomKey(RemoveDeadends),
		add_stairs = getRandomKey(AddStairs),
	}

	dungeon = DunGen.generate(dungeonOptions)

	local cell_h = math.max(window_h / (dungeon.n_rows + 1), 5)
	renderOptions.cell_size = cell_h

	texture = DunGen.render(dungeon, renderOptions)

	local font = love.graphics.getFont()
	info_texts = {}
	local info_keys = getKeys(dungeonOptions)
	table.sort(info_keys)
	for _, info_key in ipairs(info_keys) do
		local value = dungeonOptions[info_key]
		info_texts[#info_texts + 1] = love.graphics.newText(font, info_key .. ': ' .. tostring(value))
	end
end

function love.load(args)
	love.window.setTitle('DunGen')
	
	_ = love.window.setMode(1024, 720)

	generate()
end

function love.draw()
	love.graphics.draw(texture)

	for i, text in ipairs(info_texts) do
		local text_w = text:getWidth()
		love.graphics.draw(text, window_w - text_w - 25, i * 25)
	end

	for i, text in ipairs(pointer_texts) do
		local text_w = text:getWidth()
		love.graphics.draw(text, window_w - text_w - 25, window_h - i * 25 - 10)
	end
end

function love.keypressed(key, code)
	if key == 'g' then
		generate()
	end

	if key == 'q' then
		love.event.quit()
	end
end

function love.mousemoved(x, y, dx, dy, istouch)
	local r = math.floor(y / renderOptions.cell_size)
	local c = math.floor(x / renderOptions.cell_size)
	local font = love.graphics.getFont()
	local cell = tonumber(dungeon:getCell(r, c))

	pointer_texts = {}

	pointer_texts[#pointer_texts + 1] = love.graphics.newText(font, string.format('val: 0x%x', cell))
	pointer_texts[#pointer_texts + 1] = love.graphics.newText(font, 'pos: '..r..','..c)
end
