require 'src/flags'

Renderer = {}

local function fillRect(image, x1, y1, x2, y2, color)
    love.graphics.setColor(color)

    love.graphics.rectangle('fill', x1, y1, x2 - x1, y2 - y1)

    love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
end

local function scaleDungeon(dungeon, options)
	local image = {
		["cell_size"] = options["cell_size"],
		["map_style"] = options["map_style"],
	}
	image["width"] = (dungeon["n_cols"] + 1) * (image["cell_size"]) + 1
	image["height"] = (dungeon["n_rows"] + 1) * (image["cell_size"]) + 1
	image["max_x"] = image["width"] - 1
	image["max_y"] = image["height"] - 1
    image["char_x"] = math.floor((image["cell_size"] - 10) / 2) + 1
    image["char_y"] = math.floor((image["cell_size"] - 22) / 2) + 1 
	return image
end

local function getPalette()
	return {
		["colors"] = {
			["fill"] = { 0.0, 0.0, 0.0, 1.0 },
			["open"] = { 1.0, 1.0, 1.0, 1.0 },
			["open_grid"] = { 0.5, 0.5, 0.5, 1.0 },
		},
		["black"] = { 0.0, 0.0, 0.0, 1.0 },
		["white"] = { 1.0, 1.0, 1.0, 1.0 },
	}
end

local function squareGrid(dungeon, image, canvas)
	local dim = image["cell_size"]

	love.graphics.setColor(0.0, 0.0, 0.0)

	for x = 0, image["max_x"], dim do
		love.graphics.line(x, 0, x, image["max_y"])
	end

	for y = 0, image["max_y"], dim do
		love.graphics.line(0, y, image["max_x"], y)
	end
	
	love.graphics.setColor(1.0, 1.0, 1.0)
end

local function imageGrid(dungeon, image, canvas)
	squareGrid(dungeon, image, canvas)
end

local function fillImage(dungeon, image, canvas)
	local palette = getPalette()
	local color = palette["colors"]["open"]

	love.graphics.clear(color)

	imageGrid(dungeon, image, canvas)
end

--[[
    var c = new Element("canvas");
    c.width = b.width;
    c.height = b.height;
    var d = c.getContext("2d"),
        e = b.max_x,
        g = b.max_y,
        f = b.palette,
        h;
    (h = f.open) ? fill_rect(d, 0, 0, e, g, h): fill_rect(d, 0, 0, e, g, f.white);
    if (h = f.open_grid) image_grid(a, b, h, d);
    else if (h = f.grid) image_grid(a, b, h, d);
    return c
]]

local function baseLayer(dungeon, image, canvas)
    -- body
end

local function openCells(dungeon, image, canvas)
	local cell = dungeon["cell"]
	local dim = image["cell_size"]

	love.graphics.setColor(0.0, 0.0, 0.0, 1.0)

	for r = 0, dungeon["n_rows"] do
		for c = 0, dungeon["n_cols"] do
			if bit.band(cell[r][c], Flags.OPENSPACE) == 0 then
				local x = c * dim
				local y = r * dim

				love.graphics.rectangle('fill', x, y, dim, dim)
			end
		end
	end

	love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
end

local function doorAttr(door)
	local attr = {}

	if door["key"] == "arch" then
		attr["arch"] = true
	elseif door["key"] == "open" then
		attr["arch"] = true
		attr["door"] = true
	elseif door["key"] == "lock" then
		attr["arch"] = true
		attr["door"] = true
		attr["lock"] = true
	elseif door["key"] == "trap" then
		attr["arch"] = true
		attr["door"] = true
		attr["trap"] = true	
		if door["desc"] == "Lock" then attr["lock"] = true end
	elseif door["key"] == "secret" then		
		attr["arch"] = true
		attr["wall"] = true
		attr["secret"] = true
	elseif door["key"] == "portc" then
		attr["arch"] = true
		attr["portc"] = true		
	end

	return attr
end

local function imageDoors(dungeon, image, canvas)
	local list = dungeon["door"] or {}
	local cell = dungeon["cell"]
	local dim = image["cell_size"]
	local a_px = math.floor(dim / 6)
	local d_tx = math.floor(dim / 4)
	local t_tx = math.floor(dim / 3)

	local pal = getPalette()
    local arch_color = { 1.0, 0.0, 1.0, 1.0 }
    local door_color = { 1.0, 1.0, 0.0, 1.0 }
    
    for _, door in ipairs(list) do
    	local r = door["row"]
    	local y1 = r * dim
    	local y2 = y1 + dim
    	local c = door["col"]
    	local x1 = c * dim
    	local x2 = x1 + dim

        love.graphics.setColor({ 1.0, 1.0, 1.0, 1.0 })
        love.graphics.rectangle('fill', x1 + 1, y1 + 1, dim - 1, dim - 1)
        love.graphics.setColor(0.0, 0.0, 0.0, 1.0)

    	local xc, yc = 0, 0
    	if bit.band(cell[r][c - 1], Flags.OPENSPACE) ~= 0 then
    		xc = math.floor((x1 + x2) / 2)    	    	
    	else
    		yc = math.floor((y1 + y2) / 2)    		
    	end

    	local attr = doorAttr(door)

    	if attr["wall"] == true then
    		if xc ~= 0 then   
    			love.graphics.line(xc, y1, xc, y2)    			
    		else
    			love.graphics.line(x1, yc, x2, yc)
    		end
    	end

    	if attr["secret"] == true then
    		if xc ~= 0 then
    			local yc = math.floor((y1 + y2) / 2)

    			love.graphics.line(xc - 1, yc - d_tx, xc + 2, yc - d_tx)
    			love.graphics.line(xc - 2, yc - d_tx + 1, xc - 2, yc - 1)
    			love.graphics.line(xc - 1, yc, xc + 1, yc)
    			love.graphics.line(xc + 2, yc + 1, xc + 2, yc + d_tx - 1)
    			love.graphics.line(xc - 2, yc + d_tx, xc + 1, yc + d_tx)
    		else
    			local xc = math.floor((x1 + x2) / 2)

    			love.graphics.line(xc - d_tx, yc - 2, xc - d_tx, yc + 1)
    			love.graphics.line(xc - d_tx + 1, yc + 2, xc - 1, yc + 2)
    			love.graphics.line(xc, yc - 1, xc, yc + 1)
    			love.graphics.line(xc + 1, yc - 2, xc + d_tx - 1, yc - 2)
    			love.graphics.line(xc + d_tx, yc - 1, xc + d_tx, yc + 2)
    		end
    	end

    	if attr["arch"] == true then
    		if xc ~= 0 then
    			love.graphics.rectangle('fill', xc - 1, y1, 2, a_px)
    			love.graphics.rectangle('fill', xc - 1, y2 - a_px, 2, a_px)
    		else
    			love.graphics.rectangle('fill', x1, yc - 1, a_px, 2)
    			love.graphics.rectangle('fill', x2 - a_px, yc - 1, a_px, 2)
    		end
    	end

    	if attr["door"] == true then
    		if xc ~= 0 then
    			love.graphics.rectangle('line', xc - d_tx, y1 + a_px + 1, d_tx, (y2 - a_px - 1) - (y1 + a_px + 1))
    		else
    			love.graphics.rectangle('line', x1 + a_px + 1, yc - d_tx, (x2 - a_px - 1) - (x1 + a_px + 1), d_tx)
    		end
    	end

    	if attr["lock"] == true then
    		if xc ~= 0 then
    			love.graphics.line(xc, y1 + a_px + 1, xc, y2 - a_px - 1)
    		else
    			love.graphics.line(x1 + a_px + 1, yc, x2 - a_px - 1, yc)
    		end
    	end

    	if attr["trap"] == true then
    		if xc ~= 0 then
    			local yc = math.floor((y1 + y2) / 2)
    			love.graphics.line(xc - t_tx, yc, xc + t_tx, yc)
    		else
    			local xc = math.floor((x1 + x2) / 2)
    			love.graphics.line(xc, yc - t_tx, xc, yc + t_tx)
    		end
    	end

    	if attr["portc"] then
    		if xc ~= 0 then
    			for y = y1 + a_px + 2, y2 - a_px, 2 do
    				love.graphics.points(xc, y)
    			end
    		else
    			for x = x1 + a_px + 2, x2 - a_px, 2 do
    				love.graphics.points(x, yc)
    			end
    		end
    	end
    end

    love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
end

local function imageStairs(dungeon, image, canvas)
    local list = dungeon["stair"]
    local dim = image["cell_size"]
    local s_px = math.floor(dim / 2)
    local t_px = math.floor(dim / 20) + 2
    local pal = getPalette()
    local color = { 0.0, 0.0, 0.0, 1.0 }

    for _, stair in ipairs(list) do
        local x = stair["col"] * dim
        local y = stair["row"] * dim

        if stair["key"] == "up" then
            love.graphics.setColor(0.8, 0.0, 0.0, 1.0)
            love.graphics.rectangle('fill', x, y, dim, dim)
        else
            love.graphics.setColor(0.0, 0.8, 0.0, 1.0)
            love.graphics.rectangle('fill', x, y, dim, dim)
        end
    end

    love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
end

local function cellLabel(cell)
    local i = tonumber(bit.band(bit.rshift(cell, 24), 0xFF))
    if i == 0 then return nil end
    local char = string.char(i)
    return tonumber(char)
end

local function imageLabels(dungeon, image, canvas)
    local cell = dungeon["cell"]
    local dim = image["cell_size"]
    local pal = getPalette()
    
    love.graphics.setColor(0.0, 0.0, 0.0, 1.0)

    for r = 0, dungeon["n_rows"] do
        for c = 0, dungeon["n_cols"] do
            if bit.band(cell[r][c], Flags.OPENSPACE) == 0 then goto continue end

            local char = cellLabel(cell[r][c])
            if char == nil then goto continue end
            local x = (c * dim) + image["char_x"]
            local y = (r * dim) + image["char_y"]

            love.graphics.print(char, x + 0.5, y + 0.5)

            ::continue::
        end
    end

    love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
end

function Renderer.render(dungeon, options)
	local image = scaleDungeon(dungeon, options)

	local canvas = love.graphics.newCanvas(image["width"], image["height"])
	love.graphics.setCanvas(canvas)
	-- move offset by half a pixel in order to draw sharp lines
	love.graphics.translate(0.5, 0.5) 

	fillImage(dungeon, image, canvas)

    --[[
	openCells(dungeon, image, canvas)

	imageDoors(dungeon, image, canvas)
    imageLabels(dungeon, image, canvas)

    imageStairs(dungeon, image, canvas)
    --]]

	love.graphics.setCanvas()

	return canvas
end