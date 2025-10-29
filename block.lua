-- block.lua
-- Block prototype factory using lib.object; provides Block.load(name, color)
-- and stores created prototypes in the returned module table so callers can iterate it.
local Object = require("lib.object")

local Block = Object {} -- prototype table for block registry

-- Create or return an existing prototype.
-- Usage:
--   local Block = require "block"
--   local grass = Block.load("grass", {r,g,b,a})
function Block.load(name, color)
    if type(name) ~= "string" then error("Block.load: name must be a string") end
    if Block[name] then
        return Block[name]
    end

    -- create prototype using Object {}
    local proto = Object {}

    -- lifecycle methods for the prototype (called on instances)
    function proto.load(self) end
    function proto.update(self, dt) end
    function proto.draw(self, x, y, block_size)
        if not love or not love.graphics then return end
        local c = self.color or {1,1,1,1}
        love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
        love.graphics.rectangle("fill", x, y, block_size, block_size)
        love.graphics.setColor(1,1,1,1)
    end

    proto.name = name
    proto.color = color

    Block[name] = proto
    return proto
end

-- Optional convenience: return prototypes in deterministic order if needed
function Block.list()
    local names = {}
    for k, v in pairs(Block) do
        if type(k) == "string" and type(v) == "table" and v.name then
            table.insert(names, k)
        end
    end
    table.sort(names)
    local out = {}
    for _, n in ipairs(names) do out[#out+1] = Block[n] end
    return out
end

return Block