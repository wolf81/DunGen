require("dungen.table")

local Config = require("dungen.config")
local Generator = require("dungen.generator")
local Renderer = require("dungen.renderer")

io.stdout:setvbuf('no') -- show debug output live in SublimeText console

local texture, info_texts, pointer_texts = nil, {}, {}
local window_w, window_h = 1024, 720
local dungeon = nil

local renderOptions = {
	["cell_size"] = 12,
	["debug"] = true,
}

local function getRandomKey(config_tbl)
	local keys = get_keys(config_tbl)
	return keys[math.random(#keys)]
end

local function generate()
	local dungeonOptions = {
		["dungeon_size"] = "tiny", -- getRandomKey(Config.dungeon_size),
	}

	dungeon = Generator.generate(dungeonOptions)

	local cell_h = math.max(window_h / (dungeon["cols"] + 1), 5)
	renderOptions["cell_size"] = cell_h

	texture = Renderer.render(dungeon, renderOptions)

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
	local y = math.floor(y / renderOptions["cell_size"])
	local x = math.floor(x / renderOptions["cell_size"])
	local font = love.graphics.getFont()
	local cell = tonumber(dungeon:cell(x, y))

	pointer_texts = {}

	if cell ~= nil then
		pointer_texts[#pointer_texts + 1] = love.graphics.newText(font, string.format("val: 0x%x", cell))
		pointer_texts[#pointer_texts + 1] = love.graphics.newText(font, "pos: "..x..","..y)

		local roomId = tonumber(bit.rshift(bit.band(cell, Flags.ROOM_ID), 6))
		if roomId ~= 0 then
			pointer_texts[#pointer_texts + 1] = love.graphics.newText(font, "room: "..roomId)
		end
	end
end