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
    local c = self.color or { 1, 1, 1, 1 }
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(c[1], c[2], c[3], (c[4] or 1) * (a or 1))
    love.graphics.rectangle("fill", x, y, block_size, block_size)
    love.graphics.setColor(1, 1, 1, 1)
end

-- Drop this block at the specified position
function Block:drop(world, col, row, z, count)
    count = count or 1
    -- Spawn at center of block with small random offset to prevent exact superposition
    -- This ensures drops from the same 2×2 block group don't spawn exactly on top of each other
    local offset = 0.15  -- Small offset range
    local item_x = col + (math.random() * 2 - 1) * offset
    local item_y = row + (math.random() * 2 - 1) * offset
    return world:spawn_dropped_item(self, item_x, item_y, z, count)
end

return Block
