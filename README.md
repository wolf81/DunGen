DunGen
======

DunGen is a dungeon generator based on [Donjon's][0] dungeon generators written in 
Perl & JavaScript.

Eventually the goal is to mimic Donjon's JavaScript implementation as close as 
possible, however right now most of the source code is based on the Perl 
implementation as this code is more readable. 

I prefer Donjon's JavaScript implementation as it contains a few additional 
features not found in the Perl implementation.

Requirements
============

DunGen requires the [ffi][1] library for some functionality. DunGen also 
requires [LÖVE][2], however I believe this dependency could become optional by 
making a few small changes and not making use of the map rendering functionality.

_*PLEASE NOTE*: [ffi][1] is part of LuaJIT 2.1 which will be part of LÖVE 12 
(currently in development). Therefore, in order to use DunGen, you will need 
to download and build LÖVE 12 from the [LÖVE github repo][3].

DunGen *might* not work properly on 32-bit architectures as it makes use of 64-bit
numbers internally._

Usage
=====

In order to use the library, first import `dungen.lua` as such:

```lua
local DunGen = require 'src/dungen'
```

After importing DunGen, the library can be used as such:

```lua
-- generate a random dungeon
local dungeon = DunGen.generate()

-- render a map of the dungeon using the LÖVE drawing API
local texture = DunGen.render(dungeon)
```

This will generate a dungeon and render a map using the default options.

When generating a dungeon or rendering a map it's possible to supply the 
`generate()` and `render()` functions with a custom list of options, as such:

```lua
-- generate a random dungeon
local dungeon = DunGen.generate({
	["corridor_layout"] = "Straight",
	["remove_deadends"] = 75, 
})

-- render a map of the dungeon using the LÖVE drawing API
local texture = DunGen.render(dungeon, {
	["cell_size"] = 15,
})
```

The full list of options is described in the `dungen.lua` file.

The generated dungeon is a table that contains various data, such as the column 
count, row count, cells, rooms, doors, etc...

In order to process the table, we can do the following:

```lua
local dungeon = DunGen.generate()

local cell = dungeon["cell"]
for r = 0, dungeon["n_rows"] do
	for c = 0, dungeon["n_cols"] do
		local v = cell[r][c]
	end
end
```

In the above code, `v` will be some integer. Use bitmasks to figure out the data
described by the cell. The bitmasks that are available are described in 
`flags.lua`. For example, if we want to figure out if the current cell is blocked,
we can do the following:

```lua
local v = cell[r][c]
if bit.band(v, Flags.OPENSPACE) ~= 0 then
	-- this cell contains a room or corridor
end
```

[0]: https://donjon.bin.sh
[1]: https://luajit.org/ext_ffi.html
[2]: https://love2d.org
[3]: https://github.com/love2d/love/tree/12.0-development