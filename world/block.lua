local Object = require("lib.object")
local Block = Object {}

function Block:new(name, color)
    if type(name) ~= "string" then error("Block:new: name must be a string", 2) end
    self.name = name
    self.color = color
end

function Block:update(dt) end

function Block:draw(x, y, block_size)
    if not love or not love.graphics then return end
    local c = self.color or {1,1,1,1}
    love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
    love.graphics.rectangle("fill", x, y, block_size, block_size)
    love.graphics.setColor(1,1,1,1)
end

return Block