require 'src/flags'

Renderer = {}

--[[
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
]]

--[[  
    my $image = {
        'cell_size' => $dungeon->{'cell_size'},
        'map_style' => $dungeon->{'map_style'},
    };
    $image->{'width'}  = (($dungeon->{'n_cols'} + 1)
    *   $image->{'cell_size'}) + 1;
    $image->{'height'} = (($dungeon->{'n_rows'} + 1)
    *   $image->{'cell_size'}) + 1;
    $image->{'max_x'}  = $image->{'width'} - 1;
    $image->{'max_y'}  = $image->{'height'} - 1;
    
    if ($image->{'cell_size'} > 16) {
        $image->{'font'} = gdLargeFont;
    } elsif ($image->{'cell_size'} > 12) {
        $image->{'font'} = gdSmallFont;
    } else {
        $image->{'font'} = gdTinyFont;
    }
    $image->{'char_w'} = $image->{'font'}->width;
    $image->{'char_h'} = $image->{'font'}->height;
    $image->{'char_x'} = int(($image->{'cell_size'}
    -      $image->{'char_w'}) / 2) + 1;
    $image->{'char_y'} = int(($image->{'cell_size'}
    -      $image->{'char_h'}) / 2) + 1;
    
    return $image;
]]

local function scaleDungeon(dungeon)
	local image = {
		["cell_size"] = dungeon["cell_size"],
		["map_style"] = dungeon["map_style"],
	}
	image["width"] = (dungeon["n_cols"] + 1) * (image["cell_size"]) + 1
	image["height"] = (dungeon["n_rows"] + 1) * (image["cell_size"]) + 1
	image["max_x"] = image["width"] - 1
	image["max_y"] = image["height"] - 1

	return image
end

--[[
    standard: {
        colors: {
            fill: "#000000",
            open: "#ffffff",
            open_grid: "#cccccc"
        }
    },
]]

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

--[[
sub square_grid {
    my ($dungeon,$image,$color,$ih) = @_;
    my $dim = $image->{'cell_size'};
    
    my $x; for ($x = 0; $x <= $image->{'max_x'}; $x += $dim) {
        $ih->line($x,0,$x,$image->{'max_y'},$color);
    }
    my $y; for ($y = 0; $y <= $image->{'max_y'}; $y += $dim) {
        $ih->line(0,$y,$image->{'max_x'},$y,$color);
    }
    return $ih;
}
]]

--[[
    my ($dungeon,$image,$color,$ih) = @_;
    my $dim = $image->{'cell_size'};
    
    my $x; for ($x = 0; $x <= $image->{'max_x'}; $x += $dim) {
        $ih->line($x,0,$x,$image->{'max_y'},$color);
    }
    my $y; for ($y = 0; $y <= $image->{'max_y'}; $y += $dim) {
        $ih->line(0,$y,$image->{'max_x'},$y,$color);
    }
    return $ih;
]]

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
sub open_cells {
    my ($dungeon,$image,$ih) = @_;
    my $cell = $dungeon->{'cell'};
    my $dim = $image->{'cell_size'};
    my $base = $image->{'base_layer'};
    
    my $r; for ($r = 0; $r <= $dungeon->{'n_rows'}; $r++) {
        my $y1 = $r * $dim;
        my $y2 = $y1 + $dim;
        
        my $c; for ($c = 0; $c <= $dungeon->{'n_cols'}; $c++) {
            next unless ($cell->[$r][$c] & $OPENSPACE);
            
            my $x1 = $c * $dim;
            my $x2 = $x1 + $dim;
            
            $ih->copy($base,$x1,$y1,$x1,$y1,($dim+1),($dim+1));
        }
    }
    return $ih;
}

]]

local function openCells(dungeon, image, canvas)
	local cell = dungeon["cell"]
	local dim = image["cell_size"]

	love.graphics.setColor(0.0, 0.0, 0.0, 1.0)

	for r = 0, dungeon["n_rows"] do
		for c = 0, dungeon["n_cols"] do
			-- TODO: should check for Flags.OPENSPACE instead, but currently no open space assigned
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

--[[
sub image_doors {
    my ($dungeon,$image,$ih) = @_;
    my $list = $dungeon->{'door'};
    return $ih unless ($list);
    my $cell = $dungeon->{'cell'};
    my $dim = $image->{'cell_size'};
    my $a_px = int($dim / 6);
    my $d_tx = int($dim / 4);
    my $t_tx = int($dim / 3);
    my $pal = $image->{'palette'};
    my $arch_color = &get_color($pal,'wall');
    my $door_color = &get_color($pal,'door');
    
    my $door; foreach $door (@{ $list }) {
        my $r = $door->{'row'};
        my $y1 = $r * $dim;
        my $y2 = $y1 + $dim;
        my $c = $door->{'col'};
        my $x1 = $c * $dim;
        my $x2 = $x1 + $dim;
        
        my ($xc,$yc); if ($cell->[$r][$c-1] & $OPENSPACE) {
            $xc = int(($x1 + $x2) / 2);
        } else {
            $yc = int(($y1 + $y2) / 2);
        }
        my $attr = &door_attr($door);
        
        if ($attr->{'wall'}) {
            if ($xc) {
                $ih->line($xc,$y1,$xc,$y2,$arch_color);
            } else {
                $ih->line($x1,$yc,$x2,$yc,$arch_color);
            }
        }
        if ($attr->{'secret'}) {
            if ($xc) {
                my $yc = int(($y1 + $y2) / 2);
                
                $ih->line($xc-1,$yc-$d_tx,$xc+2,$yc-$d_tx,$door_color);
                $ih->line($xc-2,$yc-$d_tx+1,$xc-2,$yc-1,$door_color);
                $ih->line($xc-1,$yc,$xc+1,$yc,$door_color);
                $ih->line($xc+2,$yc+1,$xc+2,$yc+$d_tx-1,$door_color);
                $ih->line($xc-2,$yc+$d_tx,$xc+1,$yc+$d_tx,$door_color);
            } else {
                my $xc = int(($x1 + $x2) / 2);
                
                $ih->line($xc-$d_tx,$yc-2,$xc-$d_tx,$yc+1,$door_color);
                $ih->line($xc-$d_tx+1,$yc+2,$xc-1,$yc+2,$door_color);
                $ih->line($xc,$yc-1,$xc,$yc+1,$door_color);
                $ih->line($xc+1,$yc-2,$xc+$d_tx-1,$yc-2,$door_color);
                $ih->line($xc+$d_tx,$yc-1,$xc+$d_tx,$yc+2,$door_color);
            }
        }
        if ($attr->{'arch'}) {
            if ($xc) {
                $ih->filledRectangle($xc-1,$y1,$xc+1,$y1+$a_px,$arch_color);
                $ih->filledRectangle($xc-1,$y2-$a_px,$xc+1,$y2,$arch_color);
            } else {
                $ih->filledRectangle($x1,$yc-1,$x1+$a_px,$yc+1,$arch_color);
                $ih->filledRectangle($x2-$a_px,$yc-1,$x2,$yc+1,$arch_color);
            }
        }
        if ($attr->{'door'}) {
            if ($xc) {
                $ih->rectangle($xc-$d_tx,  $y1+$a_px+1,
                $xc+$d_tx,$y2-$a_px-1,$door_color);
            } else {
                $ih->rectangle($x1+$a_px+1,$yc-$d_tx,
                $x2-$a_px-1,$yc+$d_tx,$door_color);
            }
        }
        if ($attr->{'lock'}) {
            if ($xc) {
                $ih->line($xc,$y1+$a_px+1,$xc,$y2-$a_px-1,$door_color);
            } else {
                $ih->line($x1+$a_px+1,$yc,$x2-$a_px-1,$yc,$door_color);
            }
        }
        if ($attr->{'trap'}) {
            if ($xc) {
                my $yc = int(($y1 + $y2) / 2);
                $ih->line($xc-$t_tx,$yc,$xc+$t_tx,$yc,$door_color);
            } else {
                my $xc = int(($x1 + $x2) / 2);
                $ih->line($xc,$yc-$t_tx,$xc,$yc+$t_tx,$door_color);
            }
        }
        if ($attr->{'portc'}) {
            if ($xc) {
                my $y; for ($y = $y1+$a_px+2; $y < $y2-$a_px; $y += 2) {
                    $ih->setPixel($xc,$y,$door_color);
                }
            } else {
                my $x; for ($x = $x1+$a_px+2; $x < $x2-$a_px; $x += 2) {
                    $ih->setPixel($x,$yc,$door_color);
                }
            }
        }
    }
    return $ih;
}
]]

local function imageDoors(dungeon, image, canvas)
	local list = dungeon["door"] or {}
	local cell = dungeon["cell"]
	local dim = dungeon["cell_size"]
	local a_px = math.floor(dim / 6)
	local d_tx = math.floor(dim / 4)
	local t_tx = math.floor(dim / 3)

	local pal = getPalette()
    local arch_color = { 1.0, 0.0, 1.0, 1.0 }
    local door_color = { 1.0, 1.0, 0.0, 1.0 }
    
    love.graphics.setColor(0.1, 0.8, 0.2, 1.0)

    for _, door in ipairs(list) do
    	local r = door["row"]
    	local y1 = r * dim
    	local y2 = y1 + dim
    	local c = door["col"]
    	local x1 = c * dim
    	local x2 = x1 + dim

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

function Renderer.render(dungeon)
	local image = scaleDungeon(dungeon)

	local canvas = love.graphics.newCanvas(image["width"], image["height"])
	love.graphics.setCanvas(canvas)

	fillImage(dungeon, image, canvas)
	openCells(dungeon, image, canvas)

	imageDoors(dungeon, image, canvas)

	love.graphics.setCanvas()

	return canvas
end