require 'src.palette'

local mfloor, mmax, mabs = math.floor, math.max, math.abs

local function getColor(color_table, key)
    while key ~= nil do
        if color_table[key] ~= nil then return color_table[key]
        else key = ColorChain[key] end
    end

    return color_table["black"]
end

local function setPixel(x, y, color)
    love.graphics.setColor(unpack(color))
    love.graphics.points(x + 0.5, y + 0.5)
    love.graphics.setColor(1.0, 1.0, 1.0)
end

local function fillRect(x1, y1, x2, y2, color)
    love.graphics.setColor(unpack(color))
    love.graphics.rectangle('fill', x1 + 0.5, y1 + 0.5, x2 - x1, y2 - y1)
    love.graphics.setColor(1.0, 1.0, 1.0)
end

local function strokeRect(x1, y1, x2, y2, color)
    love.graphics.setColor(unpack(color))
    love.graphics.rectangle('line', x1 + 0.5, y1 + 0.5, x2 - x1, y2 - y1)
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

local function hexGrid(config, color)
    local dim = config["cell_size"]
    local a, e = dim / 3.4641016151, dim / 2
    local g = config["width"] / (3 * a)
    local b = config["height"] / e

    for f = 0, g - 1 do
        local h = f * 3 * a
        local i = h + a
        local j = h + 3 * a

        for k = 0, b - 1 do
            local l = k * e
            local o = l + e

            if (f + k) % 2 ~= 0 then
                drawLine(h, l, i, o, color)
                drawLine(i, o, j, o, color)
            else
                drawLine(i, l, h, o, color)
            end
        end
    end
end

local function vexGrid(config, color)
    local dim = config["cell_size"]
    local a, e = dim / 2, dim / 3.4641016151
    local g = config["width"] / a
    local b = config["height"] / (3 * e)

    for f = 0, b - 1 do
        local h = f * 3 * e
        local i = h + e
        local j = h + 3 * e

        for k = 0, g - 1 do
            local l = k * a
            local o = l + a

            if (f + k) % 2 ~= 0 then
                drawLine(l, h, o, i, color)
                drawLine(o, i, o, j, color)
            else
                drawLine(l, i, o, h, color)
            end
        end
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
    local Palette = config["Palette"]

    -- set background color if defined or use black background
    local bg_color = Palette["fill"] or Palette["black"]
    fillRect(0, 0, config["max_x"], config["max_y"], bg_color)
    
    -- draw grid if a grid color is defined
    local grid_color = Palette["fill_grid"] or Palette["grid"]
    if grid_color ~= nil then
        imageGrid(dungeon, config, grid_color)
    end
end


local function getDoorAttributes(door)
    if door["key"] == "arch" then
        return { ["arch"] = true }
    elseif door["key"] == "open" then
        return { ["arch"] = true, ["door"] = true }
    elseif door["key"] == "lock" then
        return { ["arch"] = true, ["door"] = true, ["lock"] = true }
    elseif door["key"] == "trap" then
        local attr = { ["arch"] = true, ["door"] = true, ["trap"] = true }
        if door["desc"] == "Lock" then attr["lock"] = true end
        return attr
    elseif door["key"] == "secret" then
        return { ["wall"] = true, ["arch"] = true, ["secret"] = true }
    elseif door["key"] == "portc" then
        return { ["arch"] = true, ["portc"] = true }
    end
end

local function imageDoors(dungeon, config)
    local doors, dim = dungeon["door"], config["cell_size"]
    local g, f, h = mfloor(dim / 6), mfloor(dim / 4), mfloor(dim / 3)
    local Palette = config["Palette"]
    local wall_color = getColor(Palette, "wall")
    local door_color = getColor(Palette, "door")

    for _, door in pairs(doors) do
        local row = door["row"]
        local y1 = row * dim - 1
        local col = door["col"]
        local x1 = col * dim - 1
        local attr = getDoorAttributes(door)
        local rotate = bit.band(dungeon["cell"][row][col - 1], Mask.OPENSPACE) ~= 0
        local y2 = y1 + dim
        local x2 = x1 + dim
        local dy = mfloor((y1 + y2) / 2)
        local dx = mfloor((x1 + x2) / 2)

        if attr["wall"] then
            if rotate then
                drawLine(dx, y1, dx, y2, wall_color)
            else
                drawLine(x1, dy, x2, dy, wall_color)
            end
        end
        if attr["arch"] then
            if rotate then
                fillRect(dx - 1, y1, dx + 1, y1 + g, wall_color)
                fillRect(dx - 1, y2 - g, dx + 1, y2, wall_color)
            else
                fillRect(x1, dy - 1, x1 + g, dy + 1, wall_color)
                fillRect(x2 - g, dy - 1, x2, dy + 1, wall_color)
            end
        end
        if attr["door"] then
            if rotate then
                strokeRect(dx - f, y1 + g + 1, dx + f, y2 - g, door_color)
            else
                strokeRect(x1 + g, dy - f, x2 - g - 1, dy + f, door_color)
            end
        end
        if attr["lock"] then
            if rotate then
                drawLine(dx, y1 + g + 1, dx, y2 - g - 1, door_color)
           else
                drawLine(x1 + g + 1, dy, x2 - g - 1, dy, door_color)
            end
        end
        if attr["trap"] then            
            if rotate then
                drawLine(dx - h, dy, dx + h, dy, door_color)
            else
                drawLine(dx, dy - h, dx, dy + h, door_color)
            end
        end
        if attr["secret"] then
            if rotate then
                drawLine(dx - 1, dy - f, dx + 2, dy - f, door_color)
                drawLine(dx - 2, dy - f + 1, dx - 2, dy - 1, door_color)
                drawLine(dx - 1, dy, dx + 1, dy, door_color)
                drawLine(dx + 2, dy + 1, dx + 2, dy + f - 1, door_color)
                drawLine(dx - 2, dy + f, dx + 1, dy + f, door_color)
            else
                drawLine(dx - f, dy - 2, dx - f, dy + 1, door_color);
                drawLine(dx - f + 1, dy + 2, dx - 1, dy + 2, door_color);
                drawLine(dx, dy - 1, dx, dy + 1, door_color);
                drawLine(dx + 1, dy - 2, dx + f - 1, dy - 2, door_color);
                drawLine(dx + f, dy - 1, dx + f, dy + 2, door_color)
            end
        end
        if attr["portc"] then
            if rotate then
                for y = y1 + g + 1, y2 - g - 1, 2 do
                    setPixel(dx, y, door_color)
                end
            else
                for x = x1 + g + 1, x2 - g - 1, 2 do
                    setPixel(x, dy, door_color)
                end
            end
        end
    end
end

local function wallShading(x1, y1, x2, y2, color)
    for x = x1, x2 do
        for y = y1, y2 do
            if (x + y) % 2 ~= 0 then
                setPixel(x, y, color)
            end
        end
    end
end

local function imageWalls(dungeon, config)
    local dim = config["cell_size"]
    local e = mmax(mfloor(dim / 4), 3)
    local Palette = config["Palette"]
    
    for r = 0, dungeon["n_rows"] do
        local y1 = r * dim
        local y2 = y1 + dim
        for c = 0, dungeon["n_cols"] do
            if bit.band(dungeon["cell"][r][c], Mask.OPENSPACE) ~= 0 then
                local x1 = c * dim
                local x2 = x1 + dim
                local bevel_color = Palette["bevel_nw"]
                if bevel_color ~= nil then
                    if bit.band(dungeon["cell"][r][c - 1], Mask.OPENSPACE) == 0 then
                        drawLine(x1 - 1, y1, x1 - 1, y2, bevel_color)
                    end
                    if bit.band(dungeon["cell"][r - 1][c], Mask.OPENSPACE) == 0 then
                        drawLine(x1, y1 - 1, x2, y1 - 1, bevel_color)
                    end
                    if g ~= nil then
                        if bit.band(dungeon["cell"][r][c + 1], Mask.OPENSPACE) == 0 then
                            drawLine(x1 - 1, y1, x1 - 1, y2, bevel_color)
                        end

                        if bit.band(dungeon["cell"][r - 1][c], Mask.OPENSPACE) == 0 then
                            drawLine(x1, y1 - 1, x2, y1 - 1, bevel_color)
                        end
                    end
                else
                    local shade_color = Palette["wall_shading"]
                    if shade_color ~= nil then
                        if bit.band(dungeon["cell"][r - 1][c - 1], Mask.OPENSPACE) == 0 then
                            wallShading(x1 - e, y1 - e, x1 - 1, y1 - 1, shade_color)
                        end
                        if bit.band(dungeon["cell"][r - 1][c], Mask.OPENSPACE) == 0 then
                            wallShading(x1, y1 - e, x2, y1 - 1, shade_color)
                        end
                        if bit.band(dungeon["cell"][r - 1][c + 1], Mask.OPENSPACE) == 0 then
                            wallShading(x2 + 1, y1 - e, x2 + e, y1 - 1, shade_color)
                        end
                        if bit.band(dungeon["cell"][r][c - 1], Mask.OPENSPACE) == 0 then
                            wallShading(x1 - e, y1, x1 - 1, y2, shade_color)
                        end
                        if bit.band(dungeon["cell"][r][c + 1], Mask.OPENSPACE) == 0 then
                            wallShading(x2 + 1, y1, x2 + e, y2, shade_color)
                        end
                        if bit.band(dungeon["cell"][r + 1][c - 1], Mask.OPENSPACE) == 0 then
                            wallShading(x1 - e, y2 + 1, x1 - 1, y2 + e, shade_color)
                        end
                        if bit.band(dungeon["cell"][r + 1][c], Mask.OPENSPACE) == 0 then
                            wallShading(x1, y2 + 1, x2, y2 + e, shade_color)
                        end
                        if bit.band(dungeon["cell"][r + 1][c - 1], Mask.OPENSPACE) == 0 then
                            wallShading(x2 + 1, y2 + 1, x2 + e, y2 + e, shade_color)
                        end
                    end
                end

                local wall_color = Palette["wall"]
                if wall_color ~= nil then
                    if bit.band(dungeon["cell"][r - 1][c], Flags.OPENSPACE) == 0 then
                        drawLine(x1, y1, x2, y1, wall_color)
                    end
                    if bit.band(dungeon["cell"][r][c - 1], Flags.OPENSPACE) == 0 then
                        drawLine(x1, y1, x1, y2, wall_color)
                    end
                    if bit.band(dungeon["cell"][r][c + 1], Flags.OPENSPACE) == 0 then
                        drawLine(x2, y1, x2, y2, wall_color)
                    end
                    if bit.band(dungeon["cell"][r + 1][c], Flags.OPENSPACE) == 0 then
                        drawLine(x1, y2, x2, y2, wall_color)
                    end
                end
            end        
        end
    end
end

local function openCells(dungeon, config)
    local dim = config["cell_size"]
    local base_layer = config["base_layer"]
    for r = 0, dungeon["n_rows"] do
        local y = r * dim

        for c = 0, dungeon["n_cols"] do            
            if bit.band(dungeon["cell"][r][c], Mask.OPENSPACE) ~= 0 then
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
        local Palette = config["Palette"]

        -- set background color if defined or use white background
        local bg_color = Palette["open"] or Palette["white"]
        fillRect(0, 0, config["max_x"], config["max_y"], bg_color)

        -- if grid color is defined, draw grid
        local grid_color = Palette["open_grid"] or Palette["grid"]
        if grid_color ~= nil then
            imageGrid(dungeon, config, grid_color)
        end
    end)

    local data = canvas:newImageData()
    local image = love.graphics.newImage(data)

    love.graphics.setCanvas(ctx)

    return image
end

local function getPalette(config)
    local Palette = (config["Palette"] ~= nil 
        and config["Palette"] 
        or Palette[config["map_style"]])

    local colors = Palette["colors"]
    for key, _ in pairs(colors) do
        Palette[key] = colors[key]
    end

    Palette["black"] = Palette["black"] or { 0.0, 0.0, 0.0 }
    Palette["white"] = Palette["white"] or { 1.0, 1.0, 1.0 }

    return Palette
end

local function scaleDungeon(dungeon, options)
    local config = {
        ["map_style"] = options["map_style"],
        ["grid"] = options["grid"],
        ["cell_size"] = options["cell_size"]
    }
    config["width"] = (dungeon["n_cols"] + 1) * config["cell_size"] + 1
    config["height"] = (dungeon["n_rows"] + 1) * config["cell_size"] + 1
    config["max_x"] = config["width"] - 1
    config["max_y"] = config["height"] - 1
    local fontSize = config["cell_size"] * 0.75
    config["font"] = love.graphics.newFont(fontSize)

    return config
end

local function cellLabel(cell)
    local value = tonumber(bit.band(bit.rshift(cell, 24), 0xFF))
    if value == 0 then return nil end
    local label = string.char(value)
    return tonumber(label)
end

local function imageLabels(dungeon, config)
    local dim = config["cell_size"]
    local d = mfloor(dim / 2)
    local Palette = config["Palette"]

    local font = config["font"]
    local color = getColor(Palette, "label")
    for r = 0, dungeon["n_rows"] do
        for c = 0, dungeon["n_cols"] do
            if bit.band(dungeon["cell"][r][c], Mask.OPENSPACE) ~= 0 then
                local label = cellLabel(dungeon["cell"][r][c])

                if label ~= nil then
                    local y = r * dim + d
                    local x = c * dim + d
                    drawString(label, x, y, font, color)
                end
            end
        end
    end
end

local function treadList(row, next_row, scaled)
    local tread_list = {}

    if next_row > row then
        local y1 = row * scaled["cell"]
        table.insert(tread_list, y1)

        local y2 = (next_row + 1) * scaled["cell"] - 1
        for y = y1, y2, scaled["tread"] do
            table.insert(tread_list, y)
        end
    elseif next_row < row then
        local x1 = (row + 1) * scaled["cell"]
        table.insert(tread_list, x1)

        local x2 = next_row * scaled["cell"] + 1
        for x = x1, x2, -(scaled["tread"]) do
            table.insert(tread_list, x)
        end    
    end

    return tread_list
end

local function scaleStairs(cell_size)
    local scaled = {
        ["cell"] = cell_size,
        ["len"] = cell_size * 2,
        ["side"] = mfloor(cell_size / 2),
        ["tread"] = mfloor(cell_size / 20) + 2,
        ["down"] = {},
    }
    for i = 0, scaled["len"] - 1, scaled["tread"] do
        scaled["down"][i] = mfloor(i / scaled["len"] * scaled["side"])
    end
    return scaled
end

local function stairDim(stair, scaled)
    local stair_dim = nil

    if stair["next_row"] ~= stair["row"] then
        local tread_list = treadList(stair["row"], stair["next_row"], scaled)
        stair_dim = {
            ["xc"] = mfloor((stair["col"] + 0.5) * scaled["cell"]) - 1,
            ["y1"] = table.remove(tread_list, 1),
            ["list"] = tread_list
        }
    else
        local tread_list = treadList(stair["col"], stair["next_col"], scaled)
        stair_dim = {
            ["yc"] = mfloor((stair["row"] + 0.5) * scaled["cell"]),
            ["x1"] = table.remove(tread_list, 1),
            ["list"] = tread_list,
        }
    end

    stair_dim["side"] = scaled["side"]
    stair_dim["down"] = scaled["down"]
    return stair_dim
end

local function imageAscend(stair_dim, color)
    if stair_dim["xc"] ~= nil then
        local x1 = stair_dim["xc"] - stair_dim["side"]
        local x2 = stair_dim["xc"] + stair_dim["side"]
        for _, h in ipairs(stair_dim["list"]) do
            drawLine(x1, h, x2, h, color)
        end
    else
        local y1 = stair_dim["yc"] - stair_dim["side"]
        local y2 = stair_dim["yc"] + stair_dim["side"]
        for _, h in ipairs(stair_dim["list"]) do
            drawLine(h, y1, h, y2, color)
        end        
    end
end

local function imageDescend(stair_dim, color)
            for k,v in pairs(stair_dim) do
                print(k, v)
            end
    if stair_dim["xc"] ~= nil then
        local x = stair_dim["xc"]
        for _, y in ipairs(stair_dim["list"]) do
            local i = mabs(y - stair_dim["y1"])
            local dx = stair_dim["down"][i]
            if dx ~= nil then drawLine(x - dx, y, x + dx, y, color) end
        end
    else
        local y = stair_dim["yc"]
        for _, x in ipairs(stair_dim["list"]) do
            local i = mabs(x - stair_dim["x1"])
            local dy = stair_dim["down"][i]
            if dy ~= nil then drawLine(x, y - dy, x, y + dy, color) end
        end
    end
end

local function imageStairs(dungeon, config)
    local stairs = dungeon["stair"]
    local scaled = scaleStairs(config["cell_size"])
    local Palette = config["Palette"]
    local color = getColor(Palette, "stair")
    for _, stair in ipairs(stairs) do
        local stair_dim = stairDim(stair, scaled)
        if stair["key"] == "up" then 
            imageAscend(stair_dim, color)
        else
            imageDescend(stair_dim, color)
        end
    end
end

local function newImage(width, height, f)
    local canvas = love.graphics.newCanvas(width, height)    
    canvas:renderTo(f or function() end)
    return canvas
end

local function debugMap(dungeon, config)
    local cell = dungeon["cell"]
    local dim = config["cell_size"]

    for r = 0, dungeon["n_rows"] do
        for c = 0, dungeon["n_cols"] do
            local x1 = c * dim - 1
            local y1 = r * dim - 1
            local x2 = x1 + dim - 1
            local y2 = y1 + dim - 1
            
            if bcheck(cell[r][c], Flags.CORRIDOR) ~= 0 then
                fillRect(x1, y1, x2, y2, { 1.0, 0.0, 0.0, 0.2 })
            end

            if bcheck(cell[r][c], Flags.ROOM) ~= 0 then
                fillRect(x1, y1, x2, y2, { 0.0, 1.0, 0.0, 0.2 })
            end

            if bcheck(cell[r][c], Flags.DOORSPACE) ~= 0 then
                fillRect(x1, y1, x2, y2, { 0.0, 1.0, 1.0, 0.5 })
            end

            if bcheck(cell[r][c], Flags.STAIRS) ~= 0 then
                fillRect(x1, y1, x2, y2, { 1.0, 0.0, 1.0, 0.8 })
            end
        end
    end
end

local function render(dungeon, options)
    local config = scaleDungeon(dungeon, options)

    return newImage(config["width"], config["height"], function(c)
        config["Palette"] = getPalette(config)        
        config["base_layer"] = baseLayer(dungeon, config)

        fillImage(dungeon, config)  
        openCells(dungeon, config)
        imageWalls(dungeon, config)
        imageDoors(dungeon, config)
        imageLabels(dungeon, config)
        imageStairs(dungeon, config)

        if options["debug"] == true then
            debugMap(dungeon, config)
        end
    end)
end

return setmetatable({
    render = render
}, {})