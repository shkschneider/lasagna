local Physics = require "src.world.physics"

local ItemDrop = {
    id = "itemdrop",
    -- TODO tostring
    -- Constants
    DROP_HEIGHT = BLOCK_SIZE / 2,
    DROP_WIDTH = BLOCK_SIZE / 2,
    MERGE_RANGE = BLOCK_SIZE,
}

-- Create a new ItemDrop
-- pickup_delay: Time (in seconds) before the drop can be picked up by the player.
--               This prevents instant re-pickup of items the player just dropped.
--               During this delay, the drop can still merge with other ready drops.
function ItemDrop.new(block_id, count, lifetime, pickup_delay)
    local itemdrop = {
        priority = 30,  -- ItemDrops update after velocity
        block_id = block_id,
        count = count or 1,
        lifetime = lifetime or 300,
        pickup_delay = pickup_delay or 0.5,  -- 0.5 seconds default pickup delay
        dead = false,  -- Mark for removal
    }
    return setmetatable(itemdrop, { __index = ItemDrop })
end

--  update method - handles drop lifetime, pickup delay, and merging
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

    -- Check for collision with other drops and merge on collision
    if entity and entity.position then
        self:checkCollisionAndMerge(entity)
    end
end

-- Check for collision with other drops and merge if they collide
-- Uses AABB (Axis-Aligned Bounding Box) collision detection with MERGE_RANGE tolerance
-- Only merges with drops that have expired pickup_delay (ready drops)
function ItemDrop.checkCollisionAndMerge(self, entity)
    -- Calculate this drop's bounding box with MERGE_RANGE tolerance
    local x1 = entity.position.x
    local y1 = entity.position.y
    local left1 = x1 - ItemDrop.DROP_WIDTH / 2 - ItemDrop.MERGE_RANGE
    local right1 = x1 + ItemDrop.DROP_WIDTH / 2 + ItemDrop.MERGE_RANGE
    local top1 = y1 - ItemDrop.DROP_HEIGHT / 2 - ItemDrop.MERGE_RANGE
    local bottom1 = y1 + ItemDrop.DROP_HEIGHT / 2 + ItemDrop.MERGE_RANGE

    -- Check collision with all other drops
    for _, other_ent in ipairs(G.entities.entities) do
        -- Skip self, non-drops, different block types, and different layers
        if other_ent ~= entity and
           other_ent.type == "drop" and
           other_ent.drop and
           other_ent.drop.block_id == self.block_id and
           other_ent.position.z == entity.position.z then

            -- Calculate other drop's bounding box
            local x2 = other_ent.position.x
            local y2 = other_ent.position.y
            local left2 = x2 - ItemDrop.DROP_WIDTH / 2
            local right2 = x2 + ItemDrop.DROP_WIDTH / 2
            local top2 = y2 - ItemDrop.DROP_HEIGHT / 2
            local bottom2 = y2 + ItemDrop.DROP_HEIGHT / 2

            -- AABB collision detection (inclusive with tolerance)
            if left1 <= right2 and right1 >= left2 and
               top1 <= bottom2 and bottom1 >= top2 then
                -- Collision detected! Merge the drops
                -- Only merge with drops that have expired pickup_delay
                if other_ent.drop.pickup_delay <= 0 then
                    self.count = self.count + other_ent.drop.count
                    other_ent.drop.dead = true
                end
            end
        end
    end
end

--  draw method - renders drop
function ItemDrop.draw(self, entity, camera_x, camera_y)
    if entity and entity.position then
        local Registry = require "src.registries"
        local proto = Registry.Blocks:get(self.block_id)
        if proto then
            -- ItemDrop is 1/2 width and 1/2 height (1/4 surface area)
            local x = entity.position.x - (camera_x or 0) - self.DROP_HEIGHT / 2
            local y = entity.position.y - (camera_y or 0) - self.DROP_HEIGHT / 2

            -- Draw the colored block
            love.graphics.setColor(proto.color)
            love.graphics.rectangle("fill", x, y, self.DROP_HEIGHT, self.DROP_HEIGHT)

            if self.count > 1 then
                -- Draw 1px gold border
                love.graphics.setColor(1, 0.8, 0, 1)
                love.graphics.rectangle("line", x, y, self.DROP_HEIGHT, self.DROP_HEIGHT)
            else
                -- Draw 1px white border
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.rectangle("line", x, y, self.DROP_HEIGHT, self.DROP_HEIGHT)
            end
        end
    end
end

return ItemDrop
