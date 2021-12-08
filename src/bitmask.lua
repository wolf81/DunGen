local bnot, band, bor = bit.bnot, bit.band, bit.bor

local function set(x, ...)
	return bor(x, ...)
end

local function clear(x, mask)	
	return band(x, bnot(mask))
end

local function check(x, ...)
	return band(x, ...)
end

return setmetatable({
	set = set,
	clear = clear,
	check = check,
}, {})