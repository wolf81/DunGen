-- copy locally for inreased performance
local bnot, band, bor = bit.bnot, bit.band, bit.bor

-- set mask(s) on a number
local function set(x, ...)
	return bor(x, ...)
end

-- clear a mask from a number
local function clear(x, mask)	
	return band(x, bnot(mask))
end

-- check the value of a mask for a number
local function check(x, ...)
	return band(x, ...)
end

-- the module
return setmetatable({
	set = set,
	clear = clear,
	check = check,
}, {})