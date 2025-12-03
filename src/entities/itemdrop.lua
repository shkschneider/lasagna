local ItemDrop = {
    id = "itemdrop",
    -- TODO tostring
}

function ItemDrop.new(block_id, count, lifetime, pickup_delay)
    local itemdrop = {
        priority = 30,  -- ItemDrops update after velocity
        block_id = block_id,
        count = count or 1,
        lifetime = lifetime or 300,
        pickup_delay = pickup_delay or 0.5,
        dead = false,  -- Mark for removal
    }
    return setmetatable(itemdrop, { __index = ItemDrop })
end

--  update method - handles drop lifetime and pickup delay
function ItemDrop.update(self, dt, entity)
    -- Decrease pickup delay
    if self.pickup_delay > 0 then
        self.pickup_delay = self.pickup_delay - dt
    end

    -- Decrease lifetime
    self.lifetime = self.lifetime - dt
    if self.lifetime <= 0 then
        self.dead = true
    end
end

--  draw method - renders drop
function ItemDrop.draw(self, entity, camera_x, camera_y)
    if entity and entity.position then
        local Registry = require "src.game.registries"
        local proto = Registry.Blocks:get(self.block_id)
        if proto then
            -- ItemDrop is 1/2 width and 1/2 height (1/4 surface area)
            local width = BLOCK_SIZE / 2
            local height = BLOCK_SIZE / 2
            local x = entity.position.x - (camera_x or 0) - width / 2
            local y = entity.position.y - (camera_y or 0) - height / 2

            -- Draw the colored block
            love.graphics.setColor(proto.color)
            love.graphics.rectangle("fill", x, y, width, height)

            if self.count > 1 then
                -- Draw 1px gold border
                love.graphics.setColor(1, 0.8, 0, 1)
                love.graphics.rectangle("line", x, y, width, height)
            else
                -- Draw 1px white border
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.rectangle("line", x, y, width, height)
            end
        end
    end
end

return ItemDrop
