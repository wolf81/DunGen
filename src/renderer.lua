local palette = {
    ["standard"] = {
        ["colors"] = {
            ["fill"] = { 0.0, 0.0, 0.0 },
            ["open"] = { 1.0, 1.0, 1.0 },
            ["open_grid"] = { 0.8, 0.8, 0.8 },
        },
    },
    ["classic"] = {
        ["colors"] = {
            ["fill"] = { 0.2, 0.6, 0.8 },
            ["open"] = { 1.0, 1.0, 1.0 },
            ["open_grid"] = { 0.2, 0.6, 0.8 },
            ["hover"] = { 0.71, 0.87, 0.95 },
        },
    },
    ["graph"] = {
        ["colors"] = {
            ["fill"] = { 1.0, 1.0, 1.0 },
            ["open"] = { 1.0, 1.0, 1.0 },
            ["grid"] = { 0.79, 0.92, 0.96 },
            ["wall"] = { 0.4, 0.4, 0.4 },
            ["wall_shading"] = { 0.4, 0.4, 0.4 },
            ["door"] = { 0.2, 0.2, 0.2 },
            ["label"] = { 0.2, 0.2, 0.2 },
            ["tag"] = { 0.4, 0.4, 0.4 },
        },
    },
}

local color_chain = {
    ["door"] = "fill",
    ["label"] = "fill",
    ["stair"] = "wall",
    ["wall"] = "fill",
    ["fill"] = "black",
    ["tag"] = "white",
}

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
    -- TODO: seems we don't need width & height params here ...
    local quad = love.graphics.newQuad(sx, sy, swidth, sheight, image)
    love.graphics.draw(image, quad, x - 0.5, y - 0.5)
end

local function squareGrid(b, color)
    local a = b["cell_size"]
    for e = 0, b["max_x"], a do
        drawLine(e, 0, e, b["max_y"], color)
    end

    for e = 0, b["max_y"], a do
        drawLine(0, e, b["max_x"], e, color)
    end
end

local function imageGrid(a, b, color)
    local grid = a["grid"]

    if grid ~= "none" then
        if grid == "hex" then
            error("not implemented")
        elseif grid == "vex" then
            error("not implemented")
        else
            squareGrid(b, color)
        end 
    end
end

local function fillImage(a, b, c)
    local d = b["max_x"]
    local e = b["max_y"]
    local g = b["palette"]

    local f = g["fill"]
    if f ~= nil then
        fillRect(0, 0, d, e, f)
    else
        fillRect(0, 0, d, e, g["black"])
    end

    local f = g["fill_grid"]
    if f ~= nil then
        imageGrid(a, b, f)
    else
        f = g["grid"]
        if f ~= nil then
            imageGrid(a, b, f)
        end
    end
end

local function getColor(color_table, key)
    while key ~= nil do
        if color_table[key] ~= nil then return color_table[key]
        else key = color_chain[key] end
    end

    return color_table["black"]
end

local function doorAttr(door)
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

local function imageDoors(a, b, c)
    local doors, e = a["door"], b["cell_size"]
    local g, f, h = math.floor(e / 6), math.floor(e / 4), math.floor(e / 3)
    local b = b["palette"]
    local i, j = getColor(b, "wall"), getColor(b, "door")

    for _, k in pairs(doors) do
        local l = k["row"]
        local o = l * e - 1
        local p = k["col"]
        local q = p * e - 1
        local ka = doorAttr(k)
        local r = bit.band(a["cell"][l][p - 1], Flags.OPENSPACE) ~= 0
        local l = o + e
        local p = q + e
        local m = math.floor((o + l) / 2)
        local n = math.floor((q + p) / 2)

        if ka["wall"] then
            if r then
                drawLine(n, o, n, l, i)
            else
                drawLine(q, m, p, m, i)
            end
        end
        if ka["arch"] then
            if r then
                fillRect(n - 1, o, n + 1, o + g, i)
                fillRect(n - 1, l - g, n + 1, l, i)
            else
                fillRect(q, m - 1, q + g, m + 1, i)
                fillRect(p - g, m - 1, p, m + 1, i)
            end
        end
        if ka["door"] then
            if r then
                strokeRect(n - f, o + g + 1, n + f, l - g, j)
            else
                strokeRect(q + g, m - f, p - g - 1, m + f, j)
            end
        end
        if ka["lock"] then
            if r then
                drawLine(n, o + g + 1, n, l - g - 1, j)
           else
                drawLine(q + g + 1, m, p - g - 1, m, j)
            end
        end
        if ka["trap"] then            
            if r then
                drawLine(n - h, m, n + h, m, j)
            else
                drawLine(n, m - h, n, m + h, j)
            end
        end
        if ka["secret"] then
            if r then
                drawLine(n - 1, m - f, n + 2, m - f, j)
                drawLine(n - 2, m - f + 1, n - 2, m - 1, j)
                drawLine(n - 1, m, n + 1, m, j)
                drawLine(n + 2, m + 1, n + 2, m + f - 1, j)
                drawLine(n - 2, m + f, n + 1, m + f, j)
            else
                drawLine(n - f, m - 2, n - f, m + 1, j);
                drawLine(n - f + 1, m + 2, n - 1, m + 2, j);
                drawLine(n, m - 1, n, m + 1, j);
                drawLine(n + 1, m - 2, n + f - 1, m - 2, j);
                drawLine(n + f, m - 1, n + f, m + 2, j)
            end
        end
        if ka["portc"] then
            if r then
                for o = o + g + 1, l - g - 1, 2 do
                    setPixel(n, o, j)
                end
            else
                for o = q + g + 1, p - g - 1, 2 do
                    setPixel(o, m, j)
                end
            end
        end
    end
end

local function wallShading(a, x1, y1, x2, y2, color)
    for x = x1, x2 do
        for y = y1, y2 do
            if (x + y) % 2 ~= 0 then
                setPixel(x, y, color)
            end
        end
    end
end

local function imageWalls(a, b, c)
    local d = b["cell_size"]
    local e = math.max(math.floor(d / 4), 3)
    local b = b["palette"]
    
    for f = 0, a["n_rows"] do
        local h = f * d
        local i = h + d
        for j = 0, a["n_cols"] do
            if bit.band(a["cell"][f][j], Flags.OPENSPACE) ~= 0 then
                local k = j * d
                local l = k + d
                local g = b["bevel_nw"]
                if g ~= nil then
                    if bit.band(a["cell"][f][j - 1], Flags.OPENSPACE) == 0 then
                        drawLine(k - 1, h, k - 1, i, g)
                    end
                    if bit.band(a["cell"][f - 1][j], Flags.OPENSPACE) == 0 then
                        drawLine(k, h - 1, l, h - 1, g)
                    end
                    if g ~= nil then
                        if bit.band(a["cell"][f][j + 1], Flags.OPENSPACE) == 0 then
                            drawLine(k - 1, h, k - 1, i, g)
                        end

                        if bit.band(a["cell"][f - 1][j], Flags.OPENSPACE) == 0 then
                            drawLine(k, h - 1, l, h - 1, g)
                        end
                    end
                else
                    g = b["wall_shading"]
                    if g ~= nil then
                        if bit.band(a["cell"][f - 1][j - 1], Flags.OPENSPACE) == 0 then
                            wallShading(c, k - e, h - e, k - 1, h - 1, g)
                        end
                        if bit.band(a["cell"][f - 1][j], Flags.OPENSPACE) == 0 then
                            wallShading(c, k, h - e, l, h - 1, g)
                        end
                        if bit.band(a["cell"][f - 1][j + 1], Flags.OPENSPACE) == 0 then
                            wallShading(c, l + 1, h - e, l + e, h - 1, g)
                        end
                        if bit.band(a["cell"][f][j - 1], Flags.OPENSPACE) == 0 then
                            wallShading(c, k - e, h, k - 1, i, g)
                        end
                        if bit.band(a["cell"][f][j + 1], Flags.OPENSPACE) == 0 then
                            wallShading(c, l + 1, h, l + e, i, g)
                        end
                        if bit.band(a["cell"][f + 1][j - 1], Flags.OPENSPACE) == 0 then
                            wallShading(c, k - e, i + 1, k - 1, i + e, g)
                        end
                        if bit.band(a["cell"][f + 1][j], Flags.OPENSPACE) == 0 then
                            wallShading(c, k, i + 1, l, i + e, g)
                        end
                        if bit.band(a["cell"][f + 1][j - 1], Flags.OPENSPACE) == 0 then
                            wallShading(c, l + 1, i + 1, l + e, i + e, g)
                        end
                    end
                end

                g = b["wall"]
                if g ~= nil then
                    if bit.band(a["cell"][f - 1][j], Flags.OPENSPACE) == 0 then
                        drawLine(k, h, l, h, g)
                    end
                    if bit.band(a["cell"][f][j - 1], Flags.OPENSPACE) == 0 then
                        drawLine(k, h, k, i, g)
                    end
                    if bit.band(a["cell"][f][j + 1], Flags.OPENSPACE) == 0 then
                        drawLine(l, h, l, i, g)
                    end
                    if bit.band(a["cell"][f + 1][j], Flags.OPENSPACE) == 0 then
                        drawLine(k, i, l, i, g)
                    end
                end
            end        
        end
    end
end

local function openCells(a, b, c)
    local d = b["cell_size"]
    local b = b["base_layer"]
    for e = 0, a["n_rows"] do
        local g = e * d

        for f = 0, a["n_cols"] do
            if bit.band(a["cell"][e][f], Flags.OPENSPACE) ~= 0 then
                local h = f * d
                drawImage(b, h, g, d, d, h, g, d, d)
            end
        end

    end
end

--[[
function hex_grid(a, b, c, d) {
    var e = b.cell_size;
    a = e / 3.4641016151;
    e = e / 2;
    var g = b.width / (3 * a);
    b = b.height / e;
    var f;
    for (f = 0; f < g; f++) {
        var h = f * 3 * a,
            i = h + a,
            j = h + 3 * a,
            k;
        for (k = 0; k < b; k++) {
            var l = k * e,
                o = l + e;
            if ((f + k) % 2 != 0) {
                draw_line(d, h, l, i, o, c);
                draw_line(d, i, o, j, o, c)
            } else draw_line(d, i, l, h, o, c)
        }
    }
    return true
}

function vex_grid(a, b, c, d) {
    var e = b.cell_size;
    a = e / 2;
    e = e / 3.4641016151;
    var g = b.width / a;
    b = b.height / (3 * e);
    var f;
    for (f = 0; f < b; f++) {
        var h = f * 3 * e,
            i = h + e,
            j = h + 3 * e,
            k;
        for (k = 0; k < g; k++) {
            var l = k * a,
                o = l + a;
            if ((f + k) % 2 != 0) {
                draw_line(d, l, h, o, i, c);
                draw_line(d, o, i, o, j, c)
            } else draw_line(d, l, i, o, h, c)
        }
    }
    return true
}
--]]

local function baseLayer(a, b)
    local ctx = love.graphics.getCanvas()

    local c = love.graphics.newCanvas(b["width"], b["height"])
    c:renderTo(function()
        --love.graphics.translate(0.5, 0.5)

        local f = b["palette"]

        local h = f["open"] 
        if h ~= nil then
            fillRect(0, 0, b["max_x"], b["max_y"], h)
        else
            fillRect(0, 0, b["max_x"], b["max_y"], f["white"])
        end

        h = f["open_grid"]
        if h ~= nil then
            imageGrid(a, b, h)
        else
            h = f["grid"]
            if h ~= nil then
                imageGrid(a, b, h)
            end
        end
    end)

    local data = c:newImageData()
    local image = love.graphics.newImage(data)

    love.graphics.setCanvas(ctx)

    return image
end

local function getPalette(a)
    local b = a["palette"] ~= nil and a["palette"] or palette[a["map_style"]]

    local c = b["colors"]
    for key, _ in pairs(c) do
        b[key] = c[key]
    end

    b["black"] = b["black"] or { 0.0, 0.0, 0.0 }
    b["white"] = b["white"] or { 1.0, 1.0, 1.0 }

    return b
end

local function scaleDungeon(dungeon, options)
    local b = {
        ["map_style"] = options["map_style"],
        ["grid"] = options["grid"],
    }
    b["cell_size"] = options["cell_size"]
    b["width"] = (dungeon["n_cols"] + 1) * b["cell_size"] + 1
    b["height"] = (dungeon["n_rows"] + 1) * b["cell_size"] + 1
    b["max_x"] = b["width"] - 1
    b["max_y"] = b["height"] - 1
    local fontSize = b["cell_size"] * 0.75
    b["font"] = love.graphics.newFont(fontSize)

    return b
end

local function cellLabel(a)
    local a = tonumber(bit.band(bit.rshift(a, 24), 0xFF))
    if a == 0 then return nil end
    local char = string.char(a)
    return tonumber(char)
end

local function imageLabels(a, b, c)
    local d = b["cell_size"]
    local e = math.floor(d / 2)
    local g = b["palette"]

    local b = b["font"]
    local g = getColor(g, "label")
    for f = 0, a["n_rows"] do
        for h = 0, a["n_cols"] do
            if bit.band(a["cell"][f][h], Flags.OPENSPACE) ~= 0 then
                local i = cellLabel(a["cell"][f][h])

                if i ~= nil then
                    local j = f * d + e
                    local k = h * d + e
                    drawString(i, k, j, b, g)
                end
            end
        end
    end
end

local function treadList(a, b, c)
    local d = {}
    if b > a then
        local a = a * c["cell"]
        table.insert(d, a)
        b = (b + 1) * c["cell"]
        for a = a, b - 1, c["tread"] do
            table.insert(d, a)
        end
    elseif b < a then
        local a = (a + 1) * c["cell"]
        table.insert(d, a)
        b = b * c["cell"]
        for a = a, b + 1, -(c["tread"]) do
            table.insert(d, a)
        end    
    end

    return d
end

local function scaleStairs(a)
    a = {
        ["cell"] = a,
        ["len"] = a * 2,
        ["side"] = math.floor(a / 2),
        ["tread"] = math.floor(a / 20) + 2,
        ["down"] = {},
    }
    for b = 0, a["len"] - 1, a["tread"] do
        a["down"][b] = math.floor(b / a["len"] * a["side"])
    end
    return a
end

local function stairDim(a, b)
    local r = nil

    if a["next_row"] ~= a["row"] then
        local c = math.floor((a["col"] + 0.5) * b["cell"]) - 1
        local a = treadList(a["row"], a["next_row"], b)
        local d = table.remove(a, 1)
        r = {
            ["xc"] = c,
            ["y1"] = d,
            ["list"] = a
        }
    else
        local c = math.floor((a["row"] + 0.5) * b["cell"])
        local a = treadList(a["col"], a["next_col"], b)
        local d = table.remove(a, 1)
        r = {
            ["yc"] = c,
            ["x1"] = d,
            ["list"] = a,
        }
    end

    r["side"] = b["side"]
    r["down"] = b["down"]
    return r
end

local function imageAscend(a, b, c)
    if a["xc"] ~= nil then
        local d = a["xc"] - a["side"]
        local e = a["xc"] + a["side"]
        for _, h in ipairs(a["list"]) do
            drawLine(d, h, e, h, b)
        end
    else
        local g = a["yc"] - a["side"]
        local f = a["yc"] + a["side"]
        for _, h in ipairs(a["list"]) do
            drawLine(h, g, h, f, b)
        end        
    end
end

local function imageDescend(a, b, c)
    if a["xc"] ~= nil then
        local d = a["xc"]
        for _, g in ipairs(a["list"]) do
            local f = a["down"][math.abs(g - a["y1"])]
            drawLine(d - f, g, d + f, g, b)
        end
    else
        local e = a["yc"]
        for _, g in ipairs(a["list"]) do
            local f = a["down"][math.abs(g - a["x1"])]
            drawLine(g, e - f, g, e + f, b)
        end
    end
end

local function imageStairs(a, b, c)
    local a = a["stair"]
    local d = scaleStairs(b["cell_size"])
    local b = b["palette"]
    local e = getColor(b, "stair")
    for _, g in ipairs(a) do
        local f = stairDim(g, d)
        if g["key"] == "up" then 
            imageAscend(f, e, c)
        else
            imageDescend(f, e, c)
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
            local x1 = c * dim + dim / 4
            local y1 = r * dim + dim / 4
            local x2 = x1 + dim / 2
            local y2 = y1 + dim / 2
            
            if bit.band(cell[r][c], Flags.CORRIDOR) ~= 0 then
                fillRect(x1, y1, x2, y2, { 1.0, 0.0, 0.0, 0.25 })
            end

            if bit.band(cell[r][c], Flags.ROOM) ~= 0 then
                fillRect(x1, y1, x2, y2, { 0.0, 1.0, 0.0, 0.25 })
            end

            if bit.band(cell[r][c], Flags.DOORSPACE) ~= 0 then
                fillRect(x1, y1, x2, y2, { 0.0, 0.0, 1.0, 0.5 })
            end

            if bit.band(cell[r][c], Flags.STAIRS) ~= 0 then
                fillRect(x1, y1, x2, y2, { 1.0, 0.0, 1.0, 0.8 })
            end
        end
    end
end

local function render(dungeon, options)
    local b = scaleDungeon(dungeon, options)

    return newImage(b["width"], b["height"], function(c)
        b["palette"] = getPalette(b)        
        b["base_layer"] = baseLayer(dungeon, b, c)

        fillImage(dungeon, b, c)  
        openCells(dungeon, b, c)
        imageWalls(dungeon, b, c)
        imageDoors(dungeon, b, c)
        imageLabels(dungeon, b, c)
        imageStairs(dungeon, b, c)

        --debugMap(dungeon, b)
    end)
end

return setmetatable({
    render = render
}, {})