--[[
var palette = {
        standard: {
            colors: {
                fill: "#000000",
                open: "#ffffff",
                open_grid: "#cccccc"
            }
        },
        classic: {
            colors: {
                fill: "#3399cc",
                open: "#ffffff",
                open_grid: "#3399cc",
                hover: "#b6def2"
            }
        },
        graph: {
            colors: {
                fill: "#ffffff",
                open: "#ffffff",
                grid: "#c9ebf5",
                wall: "#666666",
                wall_shading: "#666666",
                door: "#333333",
                label: "#333333",
                tag: "#666666"
            }
        }
    },
    color_chain = {
        door: "fill",
        label: "fill",
        stair: "wall",
        wall: "fill",
        fill: "black",
        tag: "white"
    };

function image_dungeon(a) {
    var b = scale_dungeon(a),
        c = new_image(b.width, b.height),
        d = get_palette(b);
    b.palette = d;
    d = base_layer(a, b, c);
    b.base_layer = d;
    fill_image(a, b, c);
    open_cells(a, b, c);
    image_walls(a, b, c);
    a.door && image_doors(a, b, c);
    image_labels(a, b, c);
    a.stair && image_stairs(a, b, c)
}

function new_image(a, b) {
    var c = $("map");
    c.width = a;
    c.height = b;
    return a = c.getContext("2d")
}

function scale_dungeon(a) {
    var b = {
        map_style: a.map_style,
        grid: a.grid
    };
    b.cell_size = a.cell_size;
    b.width = (a.n_cols + 1) * b.cell_size + 1;
    b.height = (a.n_rows + 1) * b.cell_size + 1;
    b.max_x = b.width - 1;
    b.max_y = b.height - 1;
    a = Math.floor(b.cell_size * 0.75);
    b.font = a.toString() + "px sans-serif";
    return b
}

function get_palette(a) {
    var b;
    b = a.palette ? a.palette : (style = a.map_style) ? palette[style] ? palette[style] : palette.standard : palette.standard;
    var c;
    if (c = b.colors) $H(c).keys().each(function(d) {
        b[d] = c[d]
    });
    b.black || (b.black = "#000000");
    b.white || (b.white = "#ffffff");
    return b
}

function get_color(a, b) {
    for (; b;) {
        if (a[b]) return a[b];
        b = color_chain[b]
    }
    return "#000000"
}

function base_layer(a, b) {
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
}

function image_grid(a, b, c, d) {
    if (a.grid != "none")
        if (a.grid == "hex") hex_grid(a, b, c, d);
        else a.grid == "vex" ? vex_grid(a, b, c, d) : square_grid(a, b, c, d);
    return true
}

function square_grid(a, b, c, d) {
    a = b.cell_size;
    var e;
    for (e = 0; e <= b.max_x; e += a) draw_line(d, e, 0, e, b.max_y, c);
    for (e = 0; e <= b.max_y; e += a) draw_line(d, 0, e, b.max_x, e, c);
    return true
}

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

function fill_image(a, b, c) {
    var d = b.max_x,
        e = b.max_y,
        g = b.palette,
        f;
    (f = g.fill) ? fill_rect(c, 0, 0, d, e, f): fill_rect(c, 0, 0, d, e, g.black);
    if (f = g.fill) fill_rect(c, 0, 0, d, e, f);
    if (f = g.fill_grid) image_grid(a, b, f, c);
    else if (f = g.grid) image_grid(a, b, f, c);
    return true
}

function open_cells(a, b, c) {
    var d = b.cell_size;
    b = b.base_layer;
    var e;
    for (e = 0; e <= a.n_rows; e++) {
        var g = e * d,
            f;
        for (f = 0; f <= a.n_cols; f++)
            if (a.cell[e][f] & OPENSPACE) {
                var h = f * d;
                c.drawImage(b, h, g, d, d, h, g, d, d)
            }
    }
    return true
}

function image_walls(a, b, c) {
    var d = b.cell_size,
        e = Math.floor(d / 4);
    if (e < 3) e = 3;
    b = b.palette;
    var g;
    cache_pixels(true);
    var f;
    for (f = 0; f <= a.n_rows; f++) {
        var h = f * d,
            i = h + d,
            j;
        for (j = 0; j <= a.n_cols; j++)
            if (a.cell[f][j] & OPENSPACE) {
                var k = j * d,
                    l = k + d;
                if (g = b.bevel_nw) {
                    a.cell[f][j - 1] & OPENSPACE || draw_line(c, k - 1, h, k - 1, i, g);
                    a.cell[f - 1][j] & OPENSPACE || draw_line(c, k, h - 1, l, h - 1, g);
                    if (g = b.bevel_se) {
                        a.cell[f][j + 1] & OPENSPACE || draw_line(c, l + 1, h + 1, l + 1, i, g);
                        a.cell[f + 1][j] & OPENSPACE || draw_line(c, k + 1, i + 1, l, i + 1, g)
                    }
                } else if (g = b.wall_shading) {
                    a.cell[f -
                        1][j - 1] & OPENSPACE || wall_shading(c, k - e, h - e, k - 1, h - 1, g);
                    a.cell[f - 1][j] & OPENSPACE || wall_shading(c, k, h - e, l, h - 1, g);
                    a.cell[f - 1][j + 1] & OPENSPACE || wall_shading(c, l + 1, h - e, l + e, h - 1, g);
                    a.cell[f][j - 1] & OPENSPACE || wall_shading(c, k - e, h, k - 1, i, g);
                    a.cell[f][j + 1] & OPENSPACE || wall_shading(c, l + 1, h, l + e, i, g);
                    a.cell[f + 1][j - 1] & OPENSPACE || wall_shading(c, k - e, i + 1, k - 1, i + e, g);
                    a.cell[f + 1][j] & OPENSPACE || wall_shading(c, k, i + 1, l, i + e, g);
                    a.cell[f + 1][j + 1] & OPENSPACE || wall_shading(c, l + 1, i + 1, l + e, i + e, g)
                }
                if (g = b.wall) {
                    a.cell[f - 1][j] & OPENSPACE ||
                        draw_line(c, k, h, l, h, g);
                    a.cell[f][j - 1] & OPENSPACE || draw_line(c, k, h, k, i, g);
                    a.cell[f][j + 1] & OPENSPACE || draw_line(c, l, h, l, i, g);
                    a.cell[f + 1][j] & OPENSPACE || draw_line(c, k, i, l, i, g)
                }
            }
    }
    dump_pixels(c);
    return true
}

function wall_shading(a, b, c, d, e, g) {
    for (b = b; b <= d; b++) {
        var f;
        for (f = c; f <= e; f++)(b + f) % 2 != 0 && set_pixel(a, b, f, g)
    }
    return true
}

function image_doors(a, b, c) {
    var d = a.door,
        e = b.cell_size,
        g = Math.floor(e / 6),
        f = Math.floor(e / 4),
        h = Math.floor(e / 3);
    b = b.palette;
    var i = get_color(b, "wall"),
        j = get_color(b, "door");
    d.each(function(k) {
        var l = k.row,
            o = l * e,
            p = k.col,
            q = p * e;
        k = door_attr(k);
        var r = a.cell[l][p - 1] & OPENSPACE;
        l = o + e;
        p = q + e;
        var m = Math.floor((o + l) / 2),
            n = Math.floor((q + p) / 2);
        if (k.wall) r ? draw_line(c, n, o, n, l, i) : draw_line(c, q, m, p, m, i);
        if (k.arch)
            if (r) {
                fill_rect(c, n - 1, o, n + 1, o + g, i);
                fill_rect(c, n - 1, l - g, n + 1, l, i)
            } else {
                fill_rect(c, q, m - 1, q + g, m + 1, i);
                fill_rect(c,
                    p - g, m - 1, p, m + 1, i)
            }
        if (k.door) r ? stroke_rect(c, n - f, o + g + 1, n + f, l - g - 1, j) : stroke_rect(c, q + g + 1, m - f, p - g - 1, m + f, j);
        if (k.lock) r ? draw_line(c, n, o + g + 1, n, l - g - 1, j) : draw_line(c, q + g + 1, m, p - g - 1, m, j);
        if (k.trap) r ? draw_line(c, n - h, m, n + h, m, j) : draw_line(c, n, m - h, n, m + h, j);
        if (k.secret)
            if (r) {
                draw_line(c, n - 1, m - f, n + 2, m - f, j);
                draw_line(c, n - 2, m - f + 1, n - 2, m - 1, j);
                draw_line(c, n - 1, m, n + 1, m, j);
                draw_line(c, n + 2, m + 1, n + 2, m + f - 1, j);
                draw_line(c, n - 2, m + f, n + 1, m + f, j)
            } else {
                draw_line(c, n - f, m - 2, n - f, m + 1, j);
                draw_line(c, n - f + 1, m + 2, n - 1, m + 2, j);
                draw_line(c, n, m -
                    1, n, m + 1, j);
                draw_line(c, n + 1, m - 2, n + f - 1, m - 2, j);
                draw_line(c, n + f, m - 1, n + f, m + 2, j)
            }
        if (k.portc)
            if (r)
                for (o = o + g + 2; o < l - g; o += 2) set_pixel(c, n, o, j);
            else
                for (o = q + g + 2; o < p - g; o += 2) set_pixel(c, o, m, j)
    });
    return true
}

function door_attr(a) {
    var b;
    if (a.key == "arch") b = {
        arch: 1
    };
    else if (a.key == "open") b = {
        arch: 1,
        door: 1
    };
    else if (a.key == "lock") b = {
        arch: 1,
        door: 1,
        lock: 1
    };
    else if (a.key == "trap") {
        b = {
            arch: 1,
            door: 1,
            trap: 1
        };
        if (/Lock/.test(a.desc)) b.lock = 1
    } else if (a.key == "secret") b = {
        wall: 1,
        arch: 1,
        secret: 1
    };
    else if (a.key == "portc") b = {
        arch: 1,
        portc: 1
    };
    return b
}

function image_labels(a, b, c) {
    var d = b.cell_size,
        e = Math.floor(d / 2),
        g = b.palette;
    b = b.font;
    g = get_color(g, "label");
    var f;
    for (f = 0; f <= a.n_rows; f++) {
        var h;
        for (h = 0; h <= a.n_cols; h++)
            if (a.cell[f][h] & OPENSPACE) {
                var i = cell_label(a.cell[f][h]);
                if (i) {
                    var j = f * d + e + 1,
                        k = h * d + e;
                    draw_string(c, i, k, j, b, g)
                }
            }
    }
    return true
}

function cell_label(a) {
    a = a >> 24 & 255;
    if (a == 0) return false;
    a = String.fromCharCode(a);
    if (!/^\w/.test(a)) return false;
    if (/[hjkl]/.test(a)) return false;
    return a
}

function image_stairs(a, b, c) {
    a = a.stair;
    var d = scale_stairs(b.cell_size);
    b = b.palette;
    var e = get_color(b, "stair");
    a.each(function(g) {
        var f = stair_dim(g, d);
        g.key == "up" ? image_ascend(f, e, c) : image_descend(f, e, c)
    });
    return true
}

function scale_stairs(a) {
    a = {
        cell: a,
        len: a * 2,
        side: Math.floor(a / 2),
        tread: Math.floor(a / 20) + 2,
        down: {}
    };
    var b;
    for (b = 0; b < a.len; b += a.tread) a.down[b] = Math.floor(b / a.len * a.side);
    return a
}

function stair_dim(a, b) {
    if (a.next_row != a.row) {
        var c = Math.floor((a.col + 0.5) * b.cell);
        a = tread_list(a.row, a.next_row, b);
        var d = a.shift();
        a = {
            xc: c,
            y1: d,
            list: a
        }
    } else {
        c = Math.floor((a.row + 0.5) * b.cell);
        a = tread_list(a.col, a.next_col, b);
        d = a.shift();
        a = {
            yc: c,
            x1: d,
            list: a
        }
    }
    a.side = b.side;
    a.down = b.down;
    return a
}

function tread_list(a, b, c) {
    var d = [];
    if (b > a) {
        a = a * c.cell;
        d.push(a);
        b = (b + 1) * c.cell;
        for (a = a; a < b; a += c.tread) d.push(a)
    } else if (b < a) {
        a = (a + 1) * c.cell;
        d.push(a);
        b = b * c.cell;
        for (a = a; a > b; a -= c.tread) d.push(a)
    }
    return d
}

function image_ascend(a, b, c) {
    if (a.xc) {
        var d = a.xc - a.side,
            e = a.xc + a.side;
        a.list.each(function(h) {
            draw_line(c, d, h, e, h, b)
        })
    } else {
        var g = a.yc - a.side,
            f = a.yc + a.side;
        a.list.each(function(h) {
            draw_line(c, h, g, h, f, b)
        })
    }
    return true
}

function image_descend(a, b, c) {
    if (a.xc) {
        var d = a.xc;
        a.list.each(function(g) {
            var f = a.down[Math.abs(g - a.y1)];
            draw_line(c, d - f, g, d + f, g, b)
        })
    } else {
        var e = a.yc;
        a.list.each(function(g) {
            var f = a.down[Math.abs(g - a.x1)];
            draw_line(c, g, e - f, g, e + f, b)
        })
    }
    return true
}
--]]

--[[
    var b = scale_dungeon(a),
        c = new_image(b.width, b.height),
        d = get_palette(b);
    b.palette = d;
    d = base_layer(a, b, c);
    b.base_layer = d;
    fill_image(a, b, c);
    open_cells(a, b, c);
    image_walls(a, b, c);
    a.door && image_doors(a, b, c);
    image_labels(a, b, c);
    a.stair && image_stairs(a, b, c)
]]

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

local function fillRect(image, x1, y1, x2, y2, color)
    love.graphics.setColor(unpack(color))

    love.graphics.rectangle('fill', x1, y1, x2 - x1, y2 - y1)

    love.graphics.setColor(1.0, 1.0, 1.0)
end

local function drawLine(image, x1, y1, x2, y2, color)
    love.graphics.setColor(unpack(color))

    love.graphics.line(x1, y1, x2, y2)

    love.graphics.setColor(1.0, 1.0, 1.0)
end

--[[
In JavaScript this method draws the image in the current context using the 
options provided
]]
local function drawImage(image, sx, sy, swidth, sheight, x, y, width, height)
    -- TODO: seems we don't need width & height params here ...
    local quad = love.graphics.newQuad(sx, sy, swidth, sheight, image)
    love.graphics.draw(image, quad, x, y)
end

--[[
function square_grid(a, b, c, d) {
    a = b.cell_size;
    var e;
    for (e = 0; e <= b.max_x; e += a) draw_line(d, e, 0, e, b.max_y, c);
    for (e = 0; e <= b.max_y; e += a) draw_line(d, 0, e, b.max_x, e, c);
    return true
}
--]]

local function squareGrid(a, b, c)
    local a = b["cell_size"]
    for e = 0, b["max_x"], a do
        drawLine(d, e, 0, e, b["max_y"], c)
    end

    for e = 0, b["max_y"], a do
        drawLine(d, 0, e, b["max_x"], e, c)
    end
end

--[[
function image_grid(a, b, c, d) {
    if (a.grid != "none")
        if (a.grid == "hex") hex_grid(a, b, c, d);
        else a.grid == "vex" ? vex_grid(a, b, c, d) : square_grid(a, b, c, d);
    return true
}
--]]

local function imageGrid(a, b, c, d)
    local grid = a["grid"]

    if grid ~= "none" then
        if grid == "hex" then
            error("not implemented")
        elseif grid == "vex" then
            error("not implemented")
        else
            squareGrid(a, b, c)
        end 
    end
end

--[[
function fill_image(a, b, c) {
    var d = b.max_x,
        e = b.max_y,
        g = b.palette,
        f;
    (f = g.fill) ? fill_rect(c, 0, 0, d, e, f): fill_rect(c, 0, 0, d, e, g.black);
    if (f = g.fill) fill_rect(c, 0, 0, d, e, f);
    if (f = g.fill_grid) image_grid(a, b, f, c);
    else if (f = g.grid) image_grid(a, b, f, c);
    return true
}
]]

local function fillImage(a, b, c)
    local d = b["max_x"]
    local e = b["max_y"]
    local g = b["palette"]

    local f = g["fill"]
    if f ~= nil then
        fillRect(c, 0, 0, d, e, f)
    else
        fillRect(c, 0, 0, d, e, g["black"])
    end

    local f = g["fill_grid"]
    if f ~= nil then
        imageGrid(a, b, f, c)
    else
        f = g["grid"]
        if f ~= nil then
            imageGrid(a, b, f, c)
        end
    end
end

--[[
function image_walls(a, b, c) {
    var d = b.cell_size,
        e = Math.floor(d / 4);
    if (e < 3) e = 3;
    b = b.palette;
    var g;
    cache_pixels(true);
    var f;
    for (f = 0; f <= a.n_rows; f++) {
        var h = f * d,
            i = h + d,
            j;
        for (j = 0; j <= a.n_cols; j++)
            if (a.cell[f][j] & OPENSPACE) {
                var k = j * d,
                    l = k + d;
                if (g = b.bevel_nw) {
                    a.cell[f][j - 1] & OPENSPACE || draw_line(c, k - 1, h, k - 1, i, g);
                    a.cell[f - 1][j] & OPENSPACE || draw_line(c, k, h - 1, l, h - 1, g);
                    if (g = b.bevel_se) {
                        a.cell[f][j + 1] & OPENSPACE || draw_line(c, l + 1, h + 1, l + 1, i, g);
                        a.cell[f + 1][j] & OPENSPACE || draw_line(c, k + 1, i + 1, l, i + 1, g)
                    }
                } else if (g = b.wall_shading) {
                    a.cell[f -
                        1][j - 1] & OPENSPACE || wall_shading(c, k - e, h - e, k - 1, h - 1, g);
                    a.cell[f - 1][j] & OPENSPACE || wall_shading(c, k, h - e, l, h - 1, g);
                    a.cell[f - 1][j + 1] & OPENSPACE || wall_shading(c, l + 1, h - e, l + e, h - 1, g);
                    a.cell[f][j - 1] & OPENSPACE || wall_shading(c, k - e, h, k - 1, i, g);
                    a.cell[f][j + 1] & OPENSPACE || wall_shading(c, l + 1, h, l + e, i, g);
                    a.cell[f + 1][j - 1] & OPENSPACE || wall_shading(c, k - e, i + 1, k - 1, i + e, g);
                    a.cell[f + 1][j] & OPENSPACE || wall_shading(c, k, i + 1, l, i + e, g);
                    a.cell[f + 1][j + 1] & OPENSPACE || wall_shading(c, l + 1, i + 1, l + e, i + e, g)
                }
                if (g = b.wall) {
                    a.cell[f - 1][j] & OPENSPACE ||
                        draw_line(c, k, h, l, h, g);
                    a.cell[f][j - 1] & OPENSPACE || draw_line(c, k, h, k, i, g);
                    a.cell[f][j + 1] & OPENSPACE || draw_line(c, l, h, l, i, g);
                    a.cell[f + 1][j] & OPENSPACE || draw_line(c, k, i, l, i, g)
                }
            }
    }
    dump_pixels(c);
    return true
}
]]

local function cachePixels(flag)
    -- body
end

local function imageWalls(a, b, c)
    local d = b["cell_size"]
    local e = math.max(math.floor(d / 4), 3)
    local b = b["palette"]
    
    cachePixels(true)

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
                        drawLine(c, k - 1, h, k - 1, i, g)
                    end
                    if bit.band(a["cell"][f - 1][j], Flags.OPENSPACE) == 0 then
                        drawLine(c, k, h - 1, l, h - 1, g)
                    end
                    g = b["bevel_se"]
                    if g ~= nil then
                        if bit.band(a["cell"][f][j + 1], Flags.OPENSPACE) == 0 then
                            drawLine(c, k - 1, h, k - 1, i, g)
                        end

                        if bit.band(a["cell"][f - 1][j], Flags.OPENSPACE) == 0 then
                            drawLine(c, k, h - 1, l, h - 1, g)
                        end
                    end
                end

                g = b["wall"]
                if g ~= nil then
                    if bit.band(a["cell"][f - 1][j], Flags.OPENSPACE) == 0 then
                        drawLine(c, k, h, l, h, g)
                    end
                    if bit.band(a["cell"][f][j - 1], Flags.OPENSPACE) == 0 then
                        drawLine(c, k, h, k, i, g)
                    end
                    if bit.band(a["cell"][f][j + 1], Flags.OPENSPACE) == 0 then
                        drawLine(c, l, h, l, i, g)
                    end
                    if bit.band(a["cell"][f + 1][j], Flags.OPENSPACE) == 0 then
                        drawLine(c, k, i, l, i, g)
                    end
                end
            end        
        end
    end
end

--[[
function open_cells(a, b, c) {
    var d = b.cell_size;
    b = b.base_layer;
    var e;
    for (e = 0; e <= a.n_rows; e++) {
        var g = e * d,
            f;
        for (f = 0; f <= a.n_cols; f++)
            if (a.cell[e][f] & OPENSPACE) {
                var h = f * d;
                c.drawImage(b, h, g, d, d, h, g, d, d)
            }
    }
    return true
}
]]

local function openCells(a, b, c)
    local d = b["cell_size"]
    b = b["base_layer"]
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

--[[
function base_layer(a, b) {
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
}
]]

local function baseLayer(a, b)
    local ctx = love.graphics.getCanvas()

    local c = love.graphics.newCanvas(b["width"], b["height"])
    c:renderTo(function()
        local f = b["palette"]

        local h = f["open"] 
        if h ~= nil then
            fillRect(c, 0, 0, b["max_x"], b["max_y"], h)
        else
            fillRect(c, 0, 0, b["max_x"], b["max_y"], f["white"])
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

--[[
function get_palette(a) {
    var b;
    b = a.palette ? a.palette : (style = a.map_style) ? palette[style] ? palette[style] : palette.standard : palette.standard;
    var c;
    if (c = b.colors) $H(c).keys().each(function(d) {
        b[d] = c[d]
    });
    b.black || (b.black = "#000000");
    b.white || (b.white = "#ffffff");
    return b
}
]]

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

local function newImage(width, height, f)
    local canvas = love.graphics.newCanvas(width, height)    
    canvas:renderTo(f or function() end)
    return canvas
end

--[[
function scale_dungeon(a) {
    var b = {
        map_style: a.map_style,
        grid: a.grid
    };
    b.cell_size = a.cell_size;
    b.width = (a.n_cols + 1) * b.cell_size + 1;
    b.height = (a.n_rows + 1) * b.cell_size + 1;
    b.max_x = b.width - 1;
    b.max_y = b.height - 1;
    a = Math.floor(b.cell_size * 0.75);
    b.font = a.toString() + "px sans-serif";
    return b
}
]]

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

--[[
function image_dungeon(a) {
    var b = scale_dungeon(a),
        c = new_image(b.width, b.height),
        d = get_palette(b);
    b.palette = d;
    d = base_layer(a, b, c);
    b.base_layer = d;
    fill_image(a, b, c);
    open_cells(a, b, c);
    image_walls(a, b, c);
    a.door && image_doors(a, b, c);
    image_labels(a, b, c);
    a.stair && image_stairs(a, b, c)
}
]]

local function render(dungeon, options)
    local b = scaleDungeon(dungeon, options)

    return newImage(b["width"], b["height"], function(c)
        b["palette"] = getPalette(b)
        
        d = baseLayer(dungeon, b, c)
        b["base_layer"] = d

        fillImage(dungeon, b, c)  
        openCells(dungeon, b, c)
        imageWalls(dungeon, b, c)
    end)
end

return setmetatable({
    render = render
}, {})