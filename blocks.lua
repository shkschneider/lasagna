-- blocks.lua
-- Thin wrapper that registers named block prototypes using block.lua
-- This version assumes the world stores prototypes (Blocks.grass etc.) and
-- therefore drawing helpers accept prototypes directly (no resolve_proto).
local Block = require "block"

local Blocks = {}

-- Define block types (keeps the small, data-first structure)
Blocks.grass = Block.load("grass", {0.2, 0.6, 0.2, 1.0})
Blocks.dirt  = Block.load("dirt",  {0.6, 0.3, 0.1, 1.0})
Blocks.stone = Block.load("stone", {0.5, 0.52, 0.55, 1.0})

-- Helper: return ordered list of block prototypes (useful for inventories)
function Blocks.list()
    return { Blocks.grass, Blocks.dirt, Blocks.stone }
end

-- Draw by world grid coords (col,row are 1-based). camera_x is optional pixel offset.
-- Expects a prototype table as the first argument.
function Blocks.draw(proto, col, row, block_size, camera_x)
    block_size = block_size or (Game and Game.BLOCK_SIZE) or 16
    camera_x = camera_x or 0
    if type(col) ~= "number" or type(row) ~= "number" then return false end

    local px = (col - 1) * block_size - camera_x
    local py = (row - 1) * block_size

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

-- Draw at pixel coordinates directly. Expects prototype table.
function Blocks.draw_px(proto, px, py, block_size)
    block_size = block_size or (Game and Game.BLOCK_SIZE) or 16
    if type(px) ~= "number" or type(py) ~= "number" then return false end

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

-- Optional: update all prototypes (if they have dynamic behavior)
function Blocks.update(dt)
    for k, proto in pairs(Block) do
        if type(proto) == "table" and type(proto.update) == "function" then
            proto:update(dt)
        end
    end
end

-- Optional helper: find block name for a prototype/instance
function Blocks.name_for(block_proto)
    if type(block_proto) == "table" and block_proto.name then return block_proto.name end
    for k, v in pairs(Blocks) do
        if v == block_proto then return k end
    end
    return nil
end

return Blocks