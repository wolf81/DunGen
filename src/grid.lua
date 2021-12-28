local Flags = require 'src/flags'

local Grid = {}
Grid.__index = Grid

function Grid:new(width, height)
	local cells = {}

	for x = 0, width - 1 do
		cells[x] = {}
		for y = 0, height - 1 do
			cells[x][y] = Flags.NOTHING
		end
	end

	return setmetatable({
		_cells = cells,
		_width = width,
		_height = height,
		
		n_rows = height - 1,
		n_cols = width - 1,
	}, Grid)
end

function Grid:size()
	return self._width, self._height
end

function Grid:isBounded(x, y)
	return x >= 0 and x < self._width and y >= 0 and y < self._height
end

function Grid:isBlocked(x, y, type)
	return self:isBounded(x, y) and self._cells[x][y] ~= Flags.NOTHING
end

function Grid:setValue(x, y, value)
	self._cells[x][y] = value
end

function Grid:value(x, y)
	if x < self._width and y < self._height then return self._cells[x][y] end
	return nil
end

return setmetatable(Grid, {
	__call = Grid.new,
})