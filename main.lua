require "src/utils"

local Config = require "src/config"

io.stdout:setvbuf('no') -- show debug output live in SublimeText console

local DunGen = require 'src/dungen'

local texture, info_texts, pointer_texts = nil, {}, {}
local dungeon = nil

local renderOptions = {
	["cell_size"] = 12,
	["grid"] = square,
	--["debug"] = true,
}

local function getRandomKey(config_tbl)
	local keys = getKeys(config_tbl)
	return keys[math.random(#keys)]
end

local function generate()
	local dungeonOptions = {
		["dungeon_size"] = "medium", --getRandomKey(Config.dungeon_size),
		["dungeon_layout"] = getRandomKey(Config.dungeon_layout),
		["doors"] = getRandomKey(Config.doors),
		["room_size"] = getRandomKey(Config.room_size),
		["room_layout"] = getRandomKey(Config.room_layout),
		["corridor_layout"] = getRandomKey(Config.corridor_layout),
		["remove_deadends"] = getRandomKey(Config.remove_deadends),
		["add_stairs"] = getRandomKey(Config.add_stairs),
	}

	dungeon = DunGen.generate(dungeonOptions)

	texture = DunGen.render(dungeon, renderOptions)

	local font = love.graphics.getFont()
	info_texts = {}
	for k, v in pairs(dungeonOptions) do
		info_texts[#info_texts + 1] = love.graphics.newText(font, k .. ': ' .. tostring(v))
	end
end

function love.load(args)
	love.window.setTitle('DunGen')
	
	_ = love.window.setMode(1024, 720)

	generate()
end

function love.draw()
	love.graphics.draw(texture)

	local window_w, window_h = love.graphics.getDimensions()

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
	if key == "g" then
		generate()
	end

	if key == "q" then
		love.event.quit()
	end
end

function love.mousemoved(x, y, dx, dy, istouch)
	local r = math.floor(y / renderOptions["cell_size"])
	local c = math.floor(x / renderOptions["cell_size"])
	local font = love.graphics.getFont()
	local cell = tonumber(dungeon:getCell(r, c))

	pointer_texts = {}

	pointer_texts[#pointer_texts + 1] = love.graphics.newText(font, string.format("val: 0x%x", cell))
	pointer_texts[#pointer_texts + 1] = love.graphics.newText(font, "pos: "..r..","..c)
end