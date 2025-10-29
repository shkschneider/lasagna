-- blocks.lua
-- Thin wrapper that registers named block prototypes using block.lua
-- Adds drawing helpers that forward to the block prototypes created in block.lua
local Block = require "block"

local Blocks = {}

-- Define block types (keeps the small, data-first structure)
Blocks.grass = Block.load("grass", {0.2, 0.6, 0.2, 1.0})
Blocks.dirt  = Block.load("dirt",  {0.6, 0.3, 0.1, 1.0})
Blocks.stone = Block.load("stone", {0.5, 0.52, 0.55, 1.0})

local function resolve_proto(name_or_proto)
    if type(name_or_proto) == "string" then
        return Block[name_or_proto]
    elseif type(name_or_proto) == "table" then
        return name_or_proto
    end
    return nil
end

function Blocks.draw(name_or_proto, col, row, block_size, camera_x)
    block_size = block_size or (Game and Game.BLOCK_SIZE) or 16
    camera_x = camera_x or 0
    if type(col) ~= "number" or type(row) ~= "number" then return false end

    local px = (col - 1) * block_size - camera_x
    local py = (row - 1) * block_size

    local proto = resolve_proto(name_or_proto)
    if proto and type(proto.draw) == "function" then
        proto:draw(px, py, block_size)
        return true
    end

    if proto and proto.color and love and love.graphics then
        local c = proto.color
        love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
        love.graphics.rectangle("fill", px, py, block_size, block_size)
        love.graphics.setColor(1,1,1,1)
        return true
    end

    return false
end

-- Optional: call load() on all prototypes (useful during love.load)
function Blocks.load()
    for k, proto in pairs(Block) do
        if type(proto) == "table" and type(proto.load) == "function" then
            proto:load()
        end
    end
end

function Blocks.update(dt)
    for k, proto in pairs(Block) do
        if type(proto) == "table" and type(proto.update) == "function" then
            proto:update(dt)
        end
    end
end

function Blocks.name_for(block_proto)
    if type(block_proto) == "table" and block_proto.name then return block_proto.name end
    for k, v in pairs(Blocks) do
        if v == block_proto then return k end
    end
    return nil
end

return Blocks