Palette = {
    standard = {
        colors = {
            fill = { 0.0, 0.0, 0.0 },
            open = { 1.0, 1.0, 1.0 },
            open_grid = { 0.8, 0.8, 0.8 },
        },
    },
    classic = {
        colors = {
            fill = { 0.2, 0.6, 0.8 },
            open = { 1.0, 1.0, 1.0 },
            open_grid = { 0.2, 0.6, 0.8 },
            hover = { 0.71, 0.87, 0.95 },
        },
    },
    graph = {
        colors = {
            fill = { 1.0, 1.0, 1.0 },
            open = { 1.0, 1.0, 1.0 },
            grid = { 0.79, 0.92, 0.96 },
            wall = { 0.4, 0.4, 0.4 },
            wall_shading = { 0.4, 0.4, 0.4 },
            door = { 0.2, 0.2, 0.2 },
            label = { 0.2, 0.2, 0.2 },
            tag = { 0.4, 0.4, 0.4 },
        },
    },
}

color_chain = {
    ["door"] = "fill",
    ["label"] = "fill",
    ["stair"] = "wall",
    ["wall"] = "fill",
    ["fill"] = "black",
    ["tag"] = "white",
}