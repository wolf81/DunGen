local BitMask = require 'src/bitmask'

local mfloor, mmax, mabs = math.floor, math.max, math.abs
local bcheck = BitMask.check

local function fillRect(x1, y1, x2, y2, color)
    love.graphics.setColor(unpack(color))
    love.graphics.rectangle('fill', x1 + 0.5, y1 + 0.5, x2 - x1, y2 - y1)
    love.graphics.setColor(1.0, 1.0, 1.0)
end

local function drawLine(x1, y1, x2, y2, color)
    love.graphics.setColor(unpack(color))
    love.graphics.line(x1 + 0.5, y1 + 0.5, x2 + 0.5, y2 + 0.5)
    love.graphics.setColor(1.0, 1.0, 1.0)
end

local function drawString(text, x, y, font, color)
    local t = love.graphics.newText(font, text)
    local w, h = t:getWidth(), t:getHeight()

    love.graphics.setColor(unpack(color))
    love.graphics.draw(t, x - w / 2, y - h / 2)
    love.graphics.setColor(1.0, 1.0, 1.0)
end

local function drawImage(image, sx, sy, swidth, sheight, x, y)
    local quad = love.graphics.newQuad(sx, sy, swidth, sheight, image)
    love.graphics.draw(image, quad, x - 0.5, y - 0.5)
end

local function squareGrid(config, color)
    local dim = config["cell_size"]

    for x = 0, config["max_x"], dim do
        drawLine(x, 0, x, config["max_y"], color)
    end

    for y = 0, config["max_y"], dim do
        drawLine(0, y, config["max_x"], y, color)
    end
end

local function imageGrid(dungeon, config, color)
    -- TODO: grid style should not be stored in dungeon, but in config instead
    local grid = config["grid"]

    if grid ~= "none" then
        if grid == "hex" then
            hexGrid(config, color)
        elseif grid == "vex" then
            vexGrid(config, color)
        else
            squareGrid(config, color)
        end 
    end
end

local function fillImage(dungeon, config)
    local palette = config["palette"]

    -- set background color if defined or use black background
    local bg_color = { 0.0, 0.0, 0.0 }
    fillRect(0, 0, config["max_x"], config["max_y"], bg_color)
    
    -- draw grid if a grid color is defined
    local grid_color = { 0.6, 0.6, 0.6 }
    if grid_color ~= nil then
        imageGrid(dungeon, config, grid_color)
    end
end

local function openCells(dungeon, config)
    local dim = config["cell_size"]
    local base_layer = config["base_layer"]
    for r = 0, dungeon["h"] do
        local y = r * dim

        for c = 0, dungeon["w"] do
            if bcheck(dungeon:cell(c, r), Flags.OPENSPACE) ~= 0 then
                local x = c * dim
                drawImage(base_layer, x, y, dim, dim, x, y)
            end
        end

    end
end

local function baseLayer(dungeon, config)
    local ctx = love.graphics.getCanvas()

    local canvas = love.graphics.newCanvas(config["width"], config["height"])
    canvas:renderTo(function()
        -- set background color if defined or use white background
        local bg_color = { 1.0, 1.0, 1.0 }
        fillRect(0, 0, config["max_x"], config["max_y"], bg_color)

        -- if grid color is defined, draw grid
        local grid_color = { 0.6, 0.6, 0.6 }
        if grid_color ~= nil then
            imageGrid(dungeon, config, grid_color)
        end
    end)

    local data = canvas:newImageData()
    local image = love.graphics.newImage(data)

    love.graphics.setCanvas(ctx)

    return image
end

local function scaleDungeon(dungeon, options)
    local config = {
        ["map_style"] = options["map_style"],
        ["grid"] = options["grid"],
        ["cell_size"] = options["cell_size"]
    }
    config["width"] = (dungeon["w"] + 1) * config["cell_size"]
    config["height"] = (dungeon["h"] + 1) * config["cell_size"]
    config["max_x"] = config["width"] - 1
    config["max_y"] = config["height"] - 1
    local fontSize = config["cell_size"] * 0.75
    config["font"] = love.graphics.newFont(fontSize)

    return config
end

local function newImage(width, height, f)
    local canvas = love.graphics.newCanvas(width, height)    
    canvas:renderTo(f or function() end)
    return canvas
end

local function debugMap(dungeon, config)
    local dim = config["cell_size"]

    for r = 0, dungeon["h"] do
        for c = 0, dungeon["w"] do
            local x1 = c * dim - 1
            local y1 = r * dim - 1
            local x2 = x1 + dim - 1
            local y2 = y1 + dim - 1
            
            if bcheck(dungeon:cell(c, r), Flags.CORRIDOR) ~= 0 then
                fillRect(x1, y1, x2, y2, { 1.0, 0.0, 0.0, 0.2 })
            end

            if bcheck(dungeon:cell(c, r), Flags.ROOM) ~= 0 then
                fillRect(x1, y1, x2, y2, { 0.0, 1.0, 0.0, 0.2 })
            end

            if bcheck(dungeon:cell(c, r), Flags.DOORSPACE) ~= 0 then
                fillRect(x1, y1, x2, y2, { 0.0, 1.0, 1.0, 0.5 })
            end

            if bcheck(dungeon:cell(c, r), Flags.STAIRS) ~= 0 then
                fillRect(x1, y1, x2, y2, { 1.0, 0.0, 1.0, 0.8 })
            end
        end
    end
end

local function render(dungeon, options)
    local config = scaleDungeon(dungeon, options)

    return newImage(config["width"], config["height"], function(c)
        config["base_layer"] = baseLayer(dungeon, config)

        fillImage(dungeon, config)  
        openCells(dungeon, config)

        if options["debug"] == true then
            debugMap(dungeon, config)
        end
    end)
end

return setmetatable({
    render = render
}, {})