-- Bullet System
-- Manages bullet entities (projectiles from weapons)

require "lib"

local Object = require "core.object"
local Systems = require "systems"
local Position = require "components.position"
local Velocity = require "components.velocity"
local Physics = require "components.physics"
local Bullet = require "components.bullet"

local BULLET_DAMAGE = 10
local BULLET_LIFETIME = 5
local BULLET_FRICTION = 1.0  -- No friction for bullets (they maintain velocity)

local BulletSystem = Object.new {
    id = "bullet",
    priority = 65,
    entities = {},
}

function BulletSystem.load(self)
    self.entities = {}
end

function BulletSystem.create_bullet(self, x, y, layer, vx, vy, width, height, color, gravity, destroys_blocks)
    local entity = {
        id = uuid(),
        position = Position.new(x, y, layer),
        velocity = Velocity.new(vx, vy),
        physics = Physics.new(gravity, BULLET_FRICTION),
        bullet = Bullet.new(BULLET_DAMAGE, BULLET_LIFETIME, width, height, color, destroys_blocks),
    }

    table.insert(self.entities, entity)

    return entity
end

function BulletSystem.update(self, dt)
    local world = Systems.get("world")
    local Registry = require "registries"
    local BLOCKS = Registry.blocks()

    for i = #self.entities, 1, -1 do
        local ent = self.entities[i]

        -- Apply physics (gravity)
        if ent.physics then
            ent.velocity.vy = ent.velocity.vy + ent.physics.gravity * dt
        end

        -- Update position
        ent.position.x = ent.position.x + ent.velocity.vx * dt
        ent.position.y = ent.position.y + ent.velocity.vy * dt

        -- Check collision with blocks
        local col, row = world:world_to_block(ent.position.x, ent.position.y)
        local block_def = world:get_block_def(ent.position.z, col, row)

        if block_def and block_def.solid then
            -- Bullet hit a block

            -- If this bullet destroys blocks, destroy it and spawn drop
            if ent.bullet.destroys_blocks then
                local block_id = world:get_block_id(ent.position.z, col, row)
                local proto = Registry.Blocks:get(block_id)

                if proto then
                    -- Remove block
                    world:set_block(ent.position.z, col, row, BLOCKS.AIR)

                    -- Spawn drop
                    if proto.drops then
                        local drop = Systems.get("drop")
                        if drop then
                            local drop_id, drop_count = proto.drops()
                            if drop_id then
                                local wx, wy = world:block_to_world(col, row)
                                drop:create_drop(
                                    wx + BLOCK_SIZE / 2,
                                    wy + BLOCK_SIZE / 2,
                                    ent.position.z,
                                    drop_id,
                                    drop_count
                                )
                            end
                        end
                    end
                end
            end

            -- Remove bullet
            table.remove(self.entities, i)
        else
            -- Decrease lifetime
            ent.bullet.lifetime = ent.bullet.lifetime - dt
            if ent.bullet.lifetime <= 0 then
                table.remove(self.entities, i)
            end
        end
    end
end

function BulletSystem.draw(self)
    local camera = Systems.get("camera")
    local camera_x, camera_y = camera:get_offset()

    for _, ent in ipairs(self.entities) do
        local x = ent.position.x - camera_x - ent.bullet.width / 2
        local y = ent.position.y - camera_y - ent.bullet.height / 2

        love.graphics.setColor(ent.bullet.color)
        love.graphics.rectangle("fill", x, y, ent.bullet.width, ent.bullet.height)
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return BulletSystem
