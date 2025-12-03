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

    -- Try to merge with nearby drops when still (on ground with no pickup delay)
    if entity and entity.position and self.pickup_delay <= 0 then
        self:tryMerge(entity)
    end
end

-- Try to merge this drop with nearby still drops of the same type
function ItemDrop.tryMerge(self, entity)
    -- Check if this drop is on ground (still)
    local drop_height = BLOCK_SIZE / 2
    local col, row = G.world:world_to_block(
        entity.position.x,
        entity.position.y + drop_height / 2
    )
    local block_def = G.world:get_block_def(entity.position.z, col, row)
    
    -- Only merge if on ground
    if not (block_def and block_def.solid) then
        return
    end

    -- Find nearby drops to merge with
    local MERGE_RANGE = BLOCK_SIZE / 2
    
    for _, other_ent in ipairs(G.entities.entities) do
        -- Skip self, non-drops, different block types, and different layers
        if other_ent ~= entity and
           other_ent.type == "drop" and
           other_ent.drop and
           other_ent.drop.block_id == self.block_id and
           other_ent.position.z == entity.position.z then
            
            -- Check if other drop is ready for merge (pickup delay expired)
            if other_ent.drop.pickup_delay <= 0 then
                -- Calculate distance
                local dx = other_ent.position.x - entity.position.x
                local dy = other_ent.position.y - entity.position.y
                local dist = math.sqrt(dx * dx + dy * dy)
                
                -- Merge if within range
                if dist < MERGE_RANGE then
                    -- Check if other drop is also on ground
                    local other_col, other_row = G.world:world_to_block(
                        other_ent.position.x,
                        other_ent.position.y + drop_height / 2
                    )
                    local other_block = G.world:get_block_def(other_ent.position.z, other_col, other_row)
                    
                    if other_block and other_block.solid then
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
