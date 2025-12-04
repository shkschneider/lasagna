local Vector = require "src.game.vector"

local Machine = {
    id = "machine",
    type = "machine",
}

-- Create a new Machine entity
-- x, y: world coordinates
-- layer: the layer (z-coordinate) 
-- block_id: the type of machine block
function Machine.new(x, y, layer, block_id)
    local machine = {
        id = id(),
        type = "machine",
        priority = 40,  -- Machines update after drops
        -- Entity properties
        position = Vector.new(x, y, layer),
        velocity = Vector.new(0, 0),  -- Machines don't move
        gravity = 0,  -- No gravity for machines
        friction = 1.0,  -- No friction needed
        -- Component properties
        block_id = block_id,
        dead = false,  -- Mark for removal
    }
    return setmetatable(machine, { __index = Machine })
end

-- Base update method - can be overridden by specific machine types
function Machine.update(self, dt)
    -- Base machines don't do anything
    -- Specific machine types should override this
end

-- Base draw method - renders the machine as a block
function Machine.draw(self, camera_x, camera_y)
    if self.position then
        local Registry = require "src.registries"
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

return Machine
