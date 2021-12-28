local Point = require 'src/utils/point'
local Container = require 'src/utils/container'
local BinTree = require 'src/utils/bin_tree'

local function random_split(container)
	local r1, r2 = nil, nil

	if math.random(0, 1) == 0 then
		r1 = Container(
			container.x, 
			container.y, 
			math.random(1, container.w), 
			container.h
		)
		r2 = Container(
			container.x + r1.w, 
			container.y, 
			container.w - r1.w, 
			container.h
		)
	else
		r1 = Container(
			container.x, 
			container.y, 
			container.w,
			math.random(1, container.h)
		)
		r2 = Container(
			container.x, 
			container.y + r1.h, 
			container.w, 
			container.h - r1.h
		)
	end

	return r1, r2
end

local function split(container, iter)
	local root = BinTree(container)
	
	if iter ~= 0 then
		local r1, r2 = random_split(container)
		root.lchild = split(r1, iter - 1)
		root.rchild = split(r2, iter - 1)
	end

	return root
end

local function generate(width, height)
	print('generate bsp')

	local main_container = Container(0, 0, width, height)

	local container_tree = split(main_container, 4)
	print(container_tree)
end

return setmetatable({
	generate = generate
}, {})