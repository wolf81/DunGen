local BinTree = {}
BinTree.__index = BinTree

function BinTree:new(leaf, lchild, rchild)
	return setmetatable({
		_leaf = leaf,
		_lchild = lchild,
		_rchild = rchild,
	}, BinTree)
end

function BinTree:getLeafs()
	if self._lchild == nil and self._rchild == nil then 
		return { self._leaf }
	else
		return { self._lchild:getLeafs(), self._rchild:getLeafs() }
	end
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

return setmetatable(BinTree, {
	__call = BinTree.new
})