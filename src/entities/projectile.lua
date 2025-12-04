local Registry = require "src.registries"

local Projectile = {
    id = "projectile",
    -- TODO tostring
}

function Projectile.new(damage, lifetime, width, height, color, destroyed_blocks)
    local projectile = {
        priority = 30,  -- Projectiles update after velocity
        damage = damage or 10,
        lifetime = lifetime or 5,
        width = width or 2,
        height = height or 2,
        color = color or {1, 1, 0, 1},  -- yellow by default
        destroyed_blocks = destroyed_blocks or 0,  -- whether bullet destroys blocks on impact
        dead = false,  -- Mark for removal
    }
    return setmetatable(projectile, { __index = Projectile })
end

--  update method - handles bullet lifetime and collision with blocks
function Projectile.update(self, dt, entity)
    -- Decrease lifetime
    self.lifetime = self.lifetime - dt
    if self.lifetime <= 0 then
        self.dead = true
        return
    end
    
    -- Check collision with blocks
    local col, row = G.world:world_to_block(entity.position.x, entity.position.y)
    local block_def = G.world:get_block_def(entity.position.z, col, row)

    if block_def and block_def.solid then
        -- Bullet hit a block

        -- If this bullet destroys blocks, destroy it and spawn drop
        if self.destroyed_blocks == 1 then
            Projectile.destroy_block(col, row, entity.position.z)
        elseif self.destroyed_blocks == 5 then
            Projectile.destroy_block(col, row, entity.position.z)
            Projectile.destroy_block(col, row - 1, entity.position.z)
            Projectile.destroy_block(col, row + 1, entity.position.z)
            Projectile.destroy_block(col - 1, row, entity.position.z)
            Projectile.destroy_block(col + 1, row, entity.position.z)
        elseif self.destroyed_blocks > 0 then
            Log.error("Not Implemented")
        end

        -- Mark for removal
        self.dead = true
    end
end

-- Helper function to destroy a block and spawn its drop
function Projectile.destroy_block(x, y, z)
    local BLOCKS = Registry.blocks()
    
    local block_id = G.world:get_block_id(z, x, y)
    local proto = Registry.Blocks:get(block_id)
    if proto then
        -- Remove block
        G.world:set_block(z, x, y, BLOCKS.AIR)
        -- Spawn drop
        if proto.drops then
            local drop_id, drop_count = proto.drops()
            if drop_id then
                local wx, wy = G.world:block_to_world(x, y)
                G.entities:newDrop(wx + BLOCK_SIZE / 2, wy + BLOCK_SIZE / 2,
                    z, drop_id, drop_count)
            end
        end
    end
end

--  draw method - renders bullet
function Projectile.draw(self, entity, camera_x, camera_y)
    if entity and entity.position then
        local x = entity.position.x - (camera_x or 0) - self.width / 2
        local y = entity.position.y - (camera_y or 0) - self.height / 2

        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill", x, y, self.width, self.height)
    end
end

return Projectile
