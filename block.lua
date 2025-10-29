local Object = require("lib.object")

local Block = {}

-- Create or return an existing prototype. This matches the call-site you wanted:
--   local Block = require "block"
--   local grass = Block.load("grass", {r,g,b,a})
function Block.load(name, color)
    if type(name) ~= "string" then error("Block.load: name must be a string") end
    if Block[name] then
        return Block[name]
    end
    local proto = Object {
        name = name,
        color = color,
    }
    Block[name] = proto
    return proto
end

function Block.update(self, dt) end

function Block.draw(self, x, y, block_size)
    if not love or not love.graphics then return end
    local c = self.color or {1,1,1,1}
    love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
    love.graphics.rectangle("fill", x, y, block_size, block_size)
    love.graphics.setColor(1,1,1,1)
end

return Block