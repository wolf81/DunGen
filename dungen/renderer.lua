local _PATH = (...):match("(.-)[^%.]+$") 

local tablex = require(_PATH .. ".tablex")

local mfloor, mmax, mabs = math.floor, math.max, math.abs

local function rendererDefaults()
    return {
        ["cell_size"]           = 20,           
        --^ number (pixels)
        ["debug"]               = false,
        --^ true|false
    }
end

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

local function fillImage(dungeon, config)
    fillRect(0, 0, config["max_x"], config["max_y"], { 0.0, 0.0, 0.0 })    
    squareGrid(config, { 0.5, 0.5, 0.5 })
end

local function openCells(dungeon, config)
    local dim = config["cell_size"]
    local base_layer = config["base_layer"]
    for r = 0, dungeon.rows do
        local y = r * dim

        for c = 0, dungeon.cols do
            if dungeon:cell(c, r) == " " then
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
        -- set background color if defined or use black background
        fillRect(0, 0, config["max_x"], config["max_y"], { 0.0, 0.0, 0.0 })

        -- if grid color is defined, draw grid
        squareGrid(config, { 0.5, 0.5, 0.5 })
    end)

    local data = canvas:newImageData()
    local image = love.graphics.newImage(data)

    love.graphics.setCanvas(ctx)

    return image
end

local function scaleDungeon(dungeon, options)
    local config = {
        ["cell_size"] = options["cell_size"]
    }
    config["width"] = (dungeon.cols + 1) * config["cell_size"]
    config["height"] = (dungeon.rows + 1) * config["cell_size"]
    config["max_x"] = config["width"] - 1
    config["max_y"] = config["height"] - 1

    return config
end

local function newImage(width, height, f)
    local canvas = love.graphics.newCanvas(width, height)    
    canvas:renderTo(f or function() end)
    return canvas
end

local function debugMap(dungeon, config)
    local dim = config["cell_size"]

    for r = 0, dungeon.rows do
        for c = 0, dungeon.cols do
            local x1 = c * dim - 1
            local y1 = r * dim - 1
            local x2 = x1 + dim - 1
            local y2 = y1 + dim - 1

            if dungeon:cell(c, r) == " " then
                fillRect(x1, y1, x2, y2, { 0.0, 0.0, 0.0, 0.0 })
            end
            
            if dungeon:cell(c, r) == "." then
                fillRect(x1, y1, x2, y2, { 0.8, 0.8, 0.8, 1.0 })
            end

            if dungeon:cell(c, r) == "+" then
                fillRect(x1, y1, x2, y2, { 0.0, 1.0, 1.0, 0.5 })
            end

            if dungeon:cell(c, r) == "/" or dungeon:cell(c, r) == "\\" then
                fillRect(x1, y1, x2, y2, { 1.0, 0.0, 1.0, 0.8 })
            end
        end
    end
end

local function render(dungeon, options)
    local options = tablex.merge(rendererDefaults(), options or {})

    local config = scaleDungeon(dungeon, options)

    return newImage(config["width"], config["height"], function()
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