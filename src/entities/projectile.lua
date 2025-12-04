local Registry = require "src.registries"
local Physics = require "src.world.physics"
local Vector = require "src.game.vector"

local Projectile = {
    id = "projectile",
    type = "bullet",
    -- TODO tostring
}

function Projectile.new(x, y, layer, vx, vy, width, height, color, gravity, destroyed_blocks)
    local projectile = {
        id = id(),
        type = "bullet",
        priority = 30,  -- Projectiles update after velocity
        -- Entity properties
        position = Vector.new(x, y, layer),
        velocity = Vector.new(vx or 0, vy or 0),
        gravity = gravity or 0,  -- Bullets typically have no gravity (or low gravity)
        friction = 1.0,  -- Friction multiplier: 1.0 = no friction (velocity maintained)
        -- Component properties
        damage = 10,
        lifetime = 5,
        width = width or 2,
        height = height or 2,
        color = color or {1, 1, 0, 1},  -- yellow by default
        destroyed_blocks = destroyed_blocks or 0,  -- whether bullet destroys blocks on impact
        dead = false,  -- Mark for removal
    }
    return setmetatable(projectile, { __index = Projectile })
end

--  update method - handles bullet physics, lifetime, and collision with blocks
function Projectile.update(self, dt)
    -- Apply gravity to velocity
    Physics.apply_gravity(self.velocity, self.gravity, dt)

    -- Apply velocity to position
    self.position.x = self.position.x + self.velocity.x * dt
    self.position.y = self.position.y + self.velocity.y * dt

    -- Decrease lifetime
    self.lifetime = self.lifetime - dt
    if self.lifetime <= 0 then
        self.dead = true
        return
    end

    -- Check collision with blocks
    local col, row = G.world:world_to_block(self.position.x, self.position.y)
    local block_def = G.world:get_block_def(self.position.z, col, row)

    if block_def and block_def.solid then
        -- Bullet hit a block

        -- If this bullet destroys blocks, destroy it and spawn drop
        if self.destroyed_blocks == 1 then
            Projectile.destroy_block(col, row, self.position.z)
        elseif self.destroyed_blocks == 5 then
            Projectile.destroy_block(col, row, self.position.z)
            Projectile.destroy_block(col, row - 1, self.position.z)
            Projectile.destroy_block(col, row + 1, self.position.z)
            Projectile.destroy_block(col - 1, row, self.position.z)
            Projectile.destroy_block(col + 1, row, self.position.z)
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
    local ItemDrop = require "src.entities.itemdrop"

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
                local drop = ItemDrop.new(wx + BLOCK_SIZE / 2, wy + BLOCK_SIZE / 2, z, drop_id, drop_count)
                G.entities:add(drop)
            end
        end
    end
end

--  draw method - renders bullet
function Projectile.draw(self, camera_x, camera_y)
    if self.position then
        local x = self.position.x - (camera_x or 0) - self.width / 2
        local y = self.position.y - (camera_y or 0) - self.height / 2

        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill", x, y, self.width, self.height)
    end
end

return Projectile
