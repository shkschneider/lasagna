local Object = require "core.object"
local VectorComponent = require "components.vector"
local PhysicsComponent = require "components.physics"
local ProjectileComponent = require "components.projectile"
local Registry = require "registries"
local BLOCKS = Registry.blocks()

local BULLET_DAMAGE = 10
local BULLET_LIFETIME = 5
local BULLET_FRICTION = 1.0  -- No friction for bullets (they maintain velocity)

local BulletSystem = Object.new {
    id = "bullet",
    priority = 65,
    entities = {},
}

function BulletSystem.newBullet(self, x, y, layer, vx, vy, width, height, color, gravity, destroys_blocks)
    local entity = {
        id = uuid(),
        position = VectorComponent.new(x, y, layer),
        velocity = VectorComponent.new(vx, vy),
        physics = PhysicsComponent.new(gravity, BULLET_FRICTION),
        bullet = ProjectileComponent.new(BULLET_DAMAGE, BULLET_LIFETIME, width, height, color, destroys_blocks),
    }
    table.insert(self.entities, entity)
    return entity
end

function BulletSystem.load(self)
    self.entities = {}
end

function BulletSystem.update(self, dt)
    for i = #self.entities, 1, -1 do
        local ent = self.entities[i]

        -- Call component updates via Object recursion
        Object.update(ent, dt)

        -- System-level coordination: Check collision with blocks
        local col, row = G.world:world_to_block(ent.position.x, ent.position.y)
        local block_def = G.world:get_block_def(ent.position.z, col, row)

        if block_def and block_def.solid then
            -- Bullet hit a block

            -- If this bullet destroys blocks, destroy it and spawn drop
            if ent.bullet.destroys_blocks then
                local block_id = G.world:get_block_id(ent.position.z, col, row)
                local proto = Registry.Blocks:get(block_id)

                if proto then
                    -- Remove block
                    G.world:set_block(ent.position.z, col, row, BLOCKS.AIR)

                    -- Spawn drop
                    if proto.drops then
                        local drop_id, drop_count = proto.drops()
                        if drop_id then
                            local wx, wy = G.world:block_to_world(col, row)
                            G.drop:newDrop(
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

            -- Remove bullet
            table.remove(self.entities, i)
        elseif ent.bullet.dead then
            -- Remove if marked dead by component (e.g., lifetime expired)
            table.remove(self.entities, i)
        end
    end
end

function BulletSystem.draw(self)
    local camera_x, camera_y = G.camera:get_offset()

    for _, ent in ipairs(self.entities) do
        -- Call component draw via Object recursion (passes camera via entity draw wrapper)
        ent.bullet:draw(ent, camera_x, camera_y)
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return BulletSystem
