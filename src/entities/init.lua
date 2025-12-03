local Love = require "core.love"
local Object = require "core.object"
local Physics = require "src.world.physics"
local Vector = require "src.game.vector"
local Projectile = require "src.entities.projectile"
local ItemDrop = require "src.entities.itemdrop"
local Registry = require "src.game.registries"
local BLOCKS = Registry.blocks()

local Entity = Object {
    id = "entity",
    priority = 60,  -- After player (20), before interface
    entities = {},
}

-- Entity type constants
Entity.TYPE_BULLET = "bullet"
Entity.TYPE_DROP = "drop"

-- Default entity settings
local BULLET_DAMAGE = 10
local BULLET_LIFETIME = 5
local BULLET_GRAVITY = 0  -- Bullets typically have no gravity (or low gravity)
local BULLET_FRICTION = 1.0  -- Friction multiplier: 1.0 = no friction (velocity maintained)

local DROP_LIFETIME = 300
local DROP_PICKUP_DELAY = 0.5
local DROP_GRAVITY = 400
local DROP_FRICTION = 0.8  -- Friction multiplier: <1.0 = friction applied (slows down)

-- Initialize the entity system
function Entity.load(self)
    self.entities = {}
    -- Initialize constants that depend on globals
    PICKUP_RANGE = BLOCK_SIZE
    MERGE_RANGE = BLOCK_SIZE
    Love.load(self)
end

-- Create a new entity with required components (position and velocity)
-- All entities have position and velocity Vectors
function Entity.newEntity(self, x, y, layer, vx, vy, entity_type, gravity, friction)
    local entity = {
        id = id(),
        type = entity_type,
        position = Vector.new(x, y, layer),
        velocity = Vector.new(vx or 0, vy or 0),
        -- Physics properties (gravity and friction)
        gravity = gravity or Physics.DEFAULT_GRAVITY,
        friction = friction or Physics.DEFAULT_FRICTION,
    }
    return entity
end

-- Spawn a bullet entity
function Entity.newBullet(self, x, y, layer, vx, vy, width, height, color, gravity, destroys_blocks)
    local entity = self:newEntity(x, y, layer, vx, vy, Entity.TYPE_BULLET, gravity or BULLET_GRAVITY, BULLET_FRICTION)

    -- Add projectile component
    entity.bullet = Projectile.new(BULLET_DAMAGE, BULLET_LIFETIME, width, height, color, destroys_blocks)

    table.insert(self.entities, entity)
    return entity
end

-- Spawn a drop entity
function Entity.newDrop(self, x, y, layer, block_id, count)
    -- Random horizontal velocity, upward initial velocity
    local vx = (math.random() - 0.5) * 50
    local vy = -50

    local entity = self:newEntity(x, y, layer, vx, vy, Entity.TYPE_DROP, DROP_GRAVITY, DROP_FRICTION)

    -- Add drop component
    entity.drop = ItemDrop.new(block_id, count, DROP_LIFETIME, DROP_PICKUP_DELAY)

    table.insert(self.entities, entity)
    return entity
end

-- Get entities by type
function Entity.getByType(self, entity_type)
    local result = {}
    for _, ent in ipairs(self.entities) do
        if ent.type == entity_type then
            table.insert(result, ent)
        end
    end
    return result
end

-- Remove an entity by id
function Entity.removeById(self, entity_id)
    for i = #self.entities, 1, -1 do
        if self.entities[i].id == entity_id then
            table.remove(self.entities, i)
            return true
        end
    end
    return false
end

-- Update all entities
function Entity.update(self, dt)
    local player_x, player_y, player_z = G.player:get_position()

    for i = #self.entities, 1, -1 do
        local ent = self.entities[i]
        if ent then -- might have despawn already
            -- Apply gravity to velocity (all entities have gravity)
            Physics.apply_gravity(ent.velocity, ent.gravity, dt)
            -- Apply velocity to position
            ent.position.x = ent.position.x + ent.velocity.x * dt
            ent.position.y = ent.position.y + ent.velocity.y * dt
            -- Call component updates via Object recursion
            -- This handles entity-specific logic (lifetime, etc.)
            Love.update(ent, dt)
            -- Type-specific system coordination
            if ent.type == Entity.TYPE_BULLET then
                self:updateBullet(ent, i)
            elseif ent.type == Entity.TYPE_DROP then
                self:updateDrop(ent, i, player_x, player_y, player_z)
            end
        end
    end
    -- Do NOT Love.update(self, dt)
end

-- TODO refactor in world
local function destroy_block(self, x, y, z)
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
                self:newDrop( wx + BLOCK_SIZE / 2, wy + BLOCK_SIZE / 2,
                    z, drop_id, drop_count)
            end
        end
    end
end

-- Bullet-specific update logic (system coordination)
function Entity.updateBullet(self, ent, index)
    -- Check collision with blocks
    local col, row = G.world:world_to_block(ent.position.x, ent.position.y)
    local block_def = G.world:get_block_def(ent.position.z, col, row)

    if block_def and block_def.solid then
        -- Bullet hit a block

        -- If this bullet destroys blocks, destroy it and spawn drop
        if ent.bullet.destroyed_blocks == 1 then
            destroy_block(self, col, row, ent.position.z)
        elseif ent.bullet.destroyed_blocks == 5 then
            destroy_block(self, col, row, ent.position.z)
            destroy_block(self, col, row - 1, ent.position.z)
            destroy_block(self, col, row + 1, ent.position.z)
            destroy_block(self, col - 1, row, ent.position.z)
            destroy_block(self, col + 1, row, ent.position.z)
        elseif ent.bullet.destroyed_blocks > 0 then
            Log.error("Not Implemented")
        end

        -- Remove bullet
        table.remove(self.entities, index)
    elseif ent.bullet.dead then
        -- Remove if marked dead by component (e.g., lifetime expired)
        table.remove(self.entities, index)
    end
end

-- Drop-specific update logic (system coordination)
function Entity.updateDrop(self, ent, index, player_x, player_y, player_z)
    -- Check collision with ground
    -- Drops are 1/2 block size, so check at their bottom edge (1/4 block offset)
    local drop_height = BLOCK_SIZE / 2
    local col, row = G.world:world_to_block(
        ent.position.x,
        ent.position.y + drop_height / 2
    )
    local block_def = G.world:get_block_def(ent.position.z, col, row)

    local on_ground = false
    if block_def and block_def.solid then
        ent.velocity.y = 0
        -- Position drop so its bottom edge rests on top of the block
        ent.position.y = row * BLOCK_SIZE - drop_height / 2
        on_ground = true
    end

    -- Apply friction only when on ground
    if on_ground then
        ent.velocity.x = ent.velocity.x * ent.friction
    end

    -- Merge with nearby drops
    if on_ground and ent.drop.pickup_delay <= 0 then
        self:tryMergeDrops(ent, index, drop_height)
    end

    -- Check pickup by player
    if ent.drop.pickup_delay <= 0 and ent.position.z == player_z then
        local dx = ent.position.x - player_x
        local dy = ent.position.y - player_y
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist < PICKUP_RANGE then
            -- Try to add to player inventory
            if G.player:add_to_inventory(ent.drop.block_id, ent.drop.count) then
                -- Successfully picked up
                table.remove(self.entities, index)
                return
            end
        end
    end

    -- Remove if marked dead by component (e.g., lifetime expired)
    if ent.drop.dead then
        table.remove(self.entities, index)
    end
end

-- Try to merge a drop with nearby drops
function Entity.tryMergeDrops(self, ent, index, drop_height)
    for j = index - 1, 1, -1 do
        local other = self.entities[j]

        -- Only merge with other drops of the same block type and layer
        if other.type == Entity.TYPE_DROP and
           other.drop.block_id == ent.drop.block_id and
           other.position.z == ent.position.z then

            local dx = other.position.x - ent.position.x
            local dy = other.position.y - ent.position.y
            local dist = math.sqrt(dx * dx + dy * dy)

            -- Merge if within range and other is also ready for pickup
            if dist < MERGE_RANGE and other.drop.pickup_delay <= 0 then
                -- Check if other drop is also on ground
                local other_col, other_row = G.world:world_to_block(
                    other.position.x,
                    other.position.y + drop_height / 2
                )
                local other_block = G.world:get_block_def(other.position.z, other_col, other_row)

                if other_block and other_block.solid then
                    -- Merge counts and remove the other drop
                    ent.drop.count = ent.drop.count + other.drop.count
                    table.remove(self.entities, j)
                end
            end
        end
    end
end

-- Draw all entities
function Entity.draw(self)
    local camera_x, camera_y = G.camera:get_offset()

    for _, ent in ipairs(self.entities) do
        if ent.type == Entity.TYPE_BULLET and ent.bullet then
            ent.bullet:draw(ent, camera_x, camera_y)
        elseif ent.type == Entity.TYPE_DROP and ent.drop then
            ent.drop:draw(ent, camera_x, camera_y)
        end
        Love.draw(ent)
    end
end

return Entity
