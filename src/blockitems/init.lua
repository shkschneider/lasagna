local Vector = require "src.game.vector"
local Registry = require "src.registries"

local BlockItem = {
    id = "blockitem",
    type = "blockitem",
}

-- Create a new BlockItem entity
-- x, y: world coordinates
-- layer: the layer (z-coordinate)
-- block_id: the type of blockitem block
function BlockItem.new(x, y, layer, block_id)
    local blockitem = {
        id = id(),
        type = "blockitem",
        priority = 40,  -- BlockItems update after drops
        -- Entity properties
        position = Vector.new(x, y, layer),
        velocity = Vector.new(0, 0),  -- BlockItems don't move
        gravity = 0,  -- No gravity for blockitems
        friction = 1.0,  -- No friction needed
        -- Component properties
        block_id = block_id,
        dead = false,  -- Mark for removal
    }
    return setmetatable(blockitem, { __index = BlockItem })
end

-- Base update method - can be overridden by specific blockitem types
function BlockItem.update(self, dt)
    -- Base blockitems don't do anything
    -- Specific blockitem types should override this
end

-- Base draw method - renders the blockitem as a block
function BlockItem.draw(self, camera_x, camera_y)
    if self.position then
        local proto = Registry.Blocks:get(self.block_id)
        if proto then
            local x = self.position.x - (camera_x or 0)
            local y = self.position.y - (camera_y or 0)

            -- Draw the colored block
            love.graphics.setColor(proto.color)
            love.graphics.rectangle("fill", x, y, BLOCK_SIZE, BLOCK_SIZE)

            -- Draw 1px white border
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.rectangle("line", x, y, BLOCK_SIZE, BLOCK_SIZE)
        end
    end
end

return BlockItem
