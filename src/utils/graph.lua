local GraphNode = require 'src/utils/graph_node'

local Graph = {}
Graph.__index = Graph

function Graph:new(item1, ...)
	return setmetatable({
		_vertices = {}
	}, Graph)
end

function Graph:addNodes(item1, ...)
	-- body
end

function Graph:addEdges(item1, item2, ...)
	-- body
end

function Graph:getNodes( ... )
	-- body
end

return setmetatable(Graph, {
	__call = Graph.new
})