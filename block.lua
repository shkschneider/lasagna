-- block.lua
-- Block prototype factory using lib.object; provides Block.load(name, color)
-- This module is a factory only: Block.load always returns a new prototype (no caching).
local Object = require("lib.object")

local Block = {}

-- Usage:
--   local Block = require "block"
--   local grass = Block.load("grass", {r,g,b,a})
function Block.load(name, color)
    if type(name) ~= "string" then error("Block.load: name must be a string") end

    -- create prototype using Object {}
    local proto = Object {}

    -- lifecycle methods for the prototype (can be overridden by callers)
    function proto.load(self) end
    function proto.update(self, dt) end

    -- draw expects pixel coordinates (x,y) and block_size
    function proto.draw(self, x, y, block_size)
        if not love or not love.graphics then return end
        local c = self.color or {1,1,1,1}
        love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
        love.graphics.rectangle("fill", x, y, block_size, block_size)
        love.graphics.setColor(1,1,1,1)
    end

    proto.name = name
    proto.color = color

    return proto
end

return Block