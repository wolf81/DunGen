require 'src/utils/table'

local BinTree = {}
BinTree.__index = BinTree

function BinTree:new(leaf, lchild, rchild)
	return setmetatable({
		_leaf = leaf,
		_lchild = lchild,
		_rchild = rchild,
	}, BinTree)
end

function BinTree:leafs()
	local leafs = leafs or {}

	if self._lchild == nil and self._rchild == nil then 
		leafs[#leafs + 1] = self._leaf
	else
		concat(leafs, self._lchild:leafs())
		concat(leafs, self._rchild:leafs())
	end

	return leafs
end

function BinTree:getLevel(level, queue)
	local queue = queue or {}
	
	if level == 1 then
		queue[#queue + 1] = self
	else
		if self._lchild ~= nil then
			self._lchild:getLevel(level - 1, queue)
		end

		if self._rchild ~= nil then
			self._rchild:getLevel(level - 1, queue)
		end
	end

	return queue
end

function BinTree:setChildren(lchild, rchild)
	self._lchild = lchild
	self._rchild = rchild
end

function BinTree:children()
	return self._lchild, self._rchild
end

return setmetatable(BinTree, {
	__call = BinTree.new
})