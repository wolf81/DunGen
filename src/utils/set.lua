local Set = {}
Set.__index = Set

function Set:new()
	return setmetatable({
		_values = {}
	}, Set)
end

function Set:contains(value)
	for _, v in ipairs(self._values) do
		if v == value then return true end
	end

	return false
end

function Set:size()
	return #self._values
end

function Set:get(index)
	if #self._values == 0 or index < 1 or index > #self._values then
		error('index out of bounds: ', index)
	end

	return self._values[index]
end

function Set:add(value)
	if self:contains(value) then return end

	self._values[#self._values + 1] = value
end

function Set:values()
	return self._values
end

function Set:__tostring()
	local s = "Set {\n"
	for k, v in pairs(self._values) do
		s = s .. '\t' .. tostring(v) .. ",\n"
	end
	s = s .. "}"

	return s
end

return setmetatable(Set, {
	__call = Set.new
})