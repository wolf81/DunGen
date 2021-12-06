--[[
Merge second table into first table. The second table cannot contain any key 
that does not exist in first table or merge will fail.
--]]
function merge(tbl1, tbl2)
	for k, v in pairs(tbl2) do
		assert(tbl1[k] ~= nil, "invalid key: " .. k)

		tbl1[k] = v
	end 

	return tbl1
end

--[[
Returns a list of keys from the given table.
]]
function getKeys(tbl)
	local n = 0
	local keys = {}

	for k, v in pairs(tbl) do
		n = n + 1
		keys[n] = k
	end

	return keys
end

--[[
Shuffle items in a table.
]]
function shuffle(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end