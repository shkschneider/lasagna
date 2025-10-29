-- block.lua
-- Block prototype factory using lib.object; provides Block(...) as a constructor that
-- creates block prototypes (each prototype is an instance of the Block prototype).
local Object = require("lib.object")

-- Block is a prototype (no inheritance). Calling Block(name, color) will create a
-- new prototype instance and call prototype:new(name, color).
local Block = Object {}

-- Instance initializer for block prototypes
function Block:new(name, color)
    if type(name) ~= "string" then error("Block:new: name must be a string", 2) end
    self.name = name
    self.color = color
end

-- Optional per-frame update (no-op by default)
function Block:update(dt) end

-- Draw expects pixel coordinates (x,y) and block_size and is called on instances/prototypes
function Block:draw(x, y, block_size)
    if not love or not love.graphics then return end
    local c = self.color or {1,1,1,1}
    love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
    love.graphics.rectangle("fill", x, y, block_size, block_size)
    love.graphics.setColor(1,1,1,1)
end

return Block