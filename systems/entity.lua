-- Entity System
-- Unified system for managing all non-player entities (drops, bullets, etc.)
-- Replaces DropSystem and BulletSystem with shared entity management logic

local Object = require "core.object"
local VectorComponent = require "components.vector"
local PhysicsComponent = require "components.physics"
local ItemDropComponent = require "components.itemdrop"
local ProjectileComponent = require "components.projectile"
local PhysicsSystem = require "systems.physics"
local Registry = require "registries"
local BLOCKS = Registry.blocks()

local MERGING_ENABLED = false

local EntitySystem = Object.new {
    id = "entity",
    priority = 65,  -- Between weapon (62) and drop (70)
    entities = {},
}

-- Entity type constants
EntitySystem.TYPE_DROP = "drop"
EntitySystem.TYPE_BULLET = "bullet"

--==============================================================================
-- Entity Creation
--==============================================================================

-- Create a drop entity
function EntitySystem.newDrop(self, x, y, layer, block_id, count)
    local entity = {
        id = uuid(),
        type = EntitySystem.TYPE_DROP,
        position = VectorComponent.new(x, y, layer),
        velocity = VectorComponent.new(),  -- Creates with x=0, y=0
        physics = PhysicsComponent.new(400, 0.8),  -- gravity: 400, friction: 0.8
        drop = ItemDropComponent.new(block_id, count, 300, 0.5),
        -- Entity dimensions for collision (drops are half block size)
        width = BLOCK_SIZE / 2,
        height = BLOCK_SIZE / 2,
    }
    -- Set initial velocity (random horizontal, upward)
    entity.velocity.x = (math.random() - 0.5) * 50
    entity.velocity.y = -50
    table.insert(self.entities, entity)
    return entity
end

-- Create a bullet entity
function EntitySystem.newBullet(self, x, y, layer, vx, vy, width, height, color, gravity, destroys_blocks)
    local BULLET_DAMAGE = 10
    local BULLET_LIFETIME = 5
    local BULLET_FRICTION = 1.0  -- No friction for bullets

    local entity = {
        id = uuid(),
        type = EntitySystem.TYPE_BULLET,
        position = VectorComponent.new(x, y, layer),
        velocity = VectorComponent.new(),  -- Creates with x=0, y=0
        physics = PhysicsComponent.new(gravity, BULLET_FRICTION),
        bullet = ProjectileComponent.new(BULLET_DAMAGE, BULLET_LIFETIME, width, height, color, destroys_blocks),
        -- Entity dimensions for collision
        width = width or 2,
        height = height or 2,
    }
    -- Set velocity (note: parameter names are vx/vy but we use x/y internally)
    entity.velocity.x = vx
    entity.velocity.y = vy
    table.insert(self.entities, entity)
    return entity
end

--==============================================================================
-- System Lifecycle
--==============================================================================

function EntitySystem.load(self)
    self.entities = {}
end

function EntitySystem.update(self, dt)
    local player_x, player_y, player_z = G.player:get_position()

    for i = #self.entities, 1, -1 do
        local ent = self.entities[i]

        -- Call component updates via Object recursion
        -- This handles physics (gravity), velocity, and type-specific lifetime
        Object.update(ent, dt)

        -- Apply physics-based collision using PhysicsSystem
        local should_remove = self:update_entity_physics(ent, dt)

        if should_remove then
            table.remove(self.entities, i)
        else
            -- Type-specific coordination
            if ent.type == EntitySystem.TYPE_DROP then
                if self:update_drop(ent, i, player_x, player_y, player_z) then
                    table.remove(self.entities, i)
                end
            elseif ent.type == EntitySystem.TYPE_BULLET then
                if self:update_bullet(ent) then
                    table.remove(self.entities, i)
                end
            end
        end
    end
end

--==============================================================================
-- Physics Update (shared by all entity types)
--==============================================================================

function EntitySystem.update_entity_physics(self, ent, dt)
    local pos = ent.position
    local vel = ent.velocity
    local phys = ent.physics
    local width = ent.width or BLOCK_SIZE / 2
    local height = ent.height or BLOCK_SIZE / 2

    -- Apply horizontal velocity with collision
    local hit_wall, new_x = PhysicsSystem.apply_horizontal_movement(
        G.world, pos, vel, width, height, dt
    )
    pos.x = new_x

    -- For bullets, stop horizontal velocity on wall hit
    if ent.type == EntitySystem.TYPE_BULLET and hit_wall then
        vel.x = 0
    end

    -- Apply vertical velocity with collision
    local on_ground, hit_ceiling, new_y = PhysicsSystem.apply_vertical_movement(
        G.world, pos, vel, width, height, 1.0, dt
    )
    pos.y = new_y

    -- Entity-type specific ground handling
    if on_ground then
        vel.y = 0

        -- Apply friction for drops on ground
        if ent.type == EntitySystem.TYPE_DROP then
            vel.x = vel.x * phys.friction
        end
    end

    -- Clamp to world bounds
    local clamped = PhysicsSystem.clamp_to_world(G.world, pos, vel, height)
    if clamped then
        on_ground = true
    end

    -- Store on_ground state for type-specific logic
    ent.on_ground = on_ground

    return false  -- Don't remove entity from physics update
end

--==============================================================================
-- Drop-specific Logic
--==============================================================================

function EntitySystem.update_drop(self, ent, index, player_x, player_y, player_z)
    local PICKUP_RANGE = BLOCK_SIZE
    local MERGE_RANGE = BLOCK_SIZE

    -- Merge with nearby drops (if enabled and on ground)
    if MERGING_ENABLED and ent.on_ground and ent.drop.pickup_delay <= 0 then
        self:try_merge_drops(ent, index)
    end

    -- Check pickup by player
    if ent.drop.pickup_delay <= 0 and ent.position.z == player_z then
        local dx = ent.position.x - player_x
        local dy = ent.position.y - player_y
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist < PICKUP_RANGE then
            -- Try to add to player inventory
            if G.player:add_to_inventory(ent.drop.block_id, ent.drop.count) then
                return true  -- Remove entity
            end
        end
    end

    -- Remove if marked dead by component (e.g., lifetime expired)
    if ent.drop.dead then
        return true
    end

    return false
end

function EntitySystem.try_merge_drops(self, ent, current_index)
    local MERGE_RANGE = BLOCK_SIZE
    local drop_height = BLOCK_SIZE / 2

    for j = current_index - 1, 1, -1 do
        local other = self.entities[j]

        -- Only merge with other drops
        if other.type ~= EntitySystem.TYPE_DROP then
            goto continue
        end

        -- Check if same block type and on same layer
        if other.drop.block_id == ent.drop.block_id and other.position.z == ent.position.z then
            local dx = other.position.x - ent.position.x
            local dy = other.position.y - ent.position.y
            local dist = math.sqrt(dx * dx + dy * dy)

            -- Merge if within range and other is also on ground with no pickup delay
            if dist < MERGE_RANGE and other.drop.pickup_delay <= 0 and other.on_ground then
                -- Merge counts and remove the other drop
                ent.drop.count = ent.drop.count + other.drop.count
                table.remove(self.entities, j)
                -- Note: Index adjustment handled by caller iterating backwards
            end
        end

        ::continue::
    end
end

--==============================================================================
-- Bullet-specific Logic
--==============================================================================

function EntitySystem.update_bullet(self, ent)
    -- Check collision with blocks for bullet-specific effects
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
                        self:newDrop(
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

        -- Remove bullet on block collision
        return true
    end

    -- Remove if marked dead by component (e.g., lifetime expired)
    if ent.bullet.dead then
        return true
    end

    return false
end

--==============================================================================
-- Drawing
--==============================================================================

function EntitySystem.draw(self)
    local camera_x, camera_y = G.camera:get_offset()

    for _, ent in ipairs(self.entities) do
        if ent.type == EntitySystem.TYPE_DROP then
            ent.drop:draw(ent, camera_x, camera_y)
        elseif ent.type == EntitySystem.TYPE_BULLET then
            ent.bullet:draw(ent, camera_x, camera_y)
        end
    end

    -- Reset color to white for subsequent rendering
    love.graphics.setColor(1, 1, 1, 1)
end

return EntitySystem
