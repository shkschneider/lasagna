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

    -- Try to merge with nearby drops when still (on ground)
    -- New drops can merge with existing ready drops
    if entity and entity.position then
        if Physics.is_on_ground(G.world, entity.position, self.DROP_WIDTH, self.DROP_HEIGHT) then
            self:tryMerge(entity)
        end
    end
end

-- Try to merge this drop with nearby still drops of the same type
-- This drop can have any pickup_delay, but will only merge WITH drops that are ready
-- (pickup_delay <= 0). This allows newly spawned drops to merge with existing drops.
function ItemDrop.tryMerge(self, entity)
    init_constants()

    -- Note: This drop's on_ground check is already done in update()
    -- Find nearby drops to merge with
    for _, other_ent in ipairs(G.entities.entities) do
        -- Skip self, non-drops, different block types, and different layers
        if other_ent ~= entity and
           other_ent.type == "drop" and
           other_ent.drop and
           other_ent.drop.block_id == self.block_id and
           other_ent.position.z == entity.position.z then

            -- Check if other drop is ready for merge (pickup delay expired and on ground)
            if other_ent.drop.pickup_delay <= 0 then
                -- Calculate distance
                local dx = other_ent.position.x - entity.position.x
                local dy = other_ent.position.y - entity.position.y
                local dist = math.sqrt(dx * dx + dy * dy)

                -- Merge if within range
                if dist < self.MERGE_RANGE then
                    -- Check if other drop is also on ground
                    if Physics.is_on_ground(G.world, other_ent.position, self.DROP_WIDTH, self.DROP_HEIGHT) then
                        -- Merge counts and mark the other drop as dead
                        self.count = self.count + other_ent.drop.count
                        other_ent.drop.dead = true
                    end
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
