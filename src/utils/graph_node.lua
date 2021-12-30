local GraphNode = {}

function GraphNode:new(id, data) 
	return setmetatable({
		id = id,
		data = data,
		connections = {},
	}, GraphNode)
end

function GraphNode:connect(node1, ...)
	self.connections[node1.id] = node1
end

return setmetatable(GraphNode, {
	__call = GraphNode.new
})