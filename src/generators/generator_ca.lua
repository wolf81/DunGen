local function generate()
	print('generate ca')
end

return setmetatable({
	generate = generate
}, {})