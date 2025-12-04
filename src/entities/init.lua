local Love = require "core.love"
local Object = require "core.object"
local Physics = require "src.world.physics"
local Vector = require "src.game.vector"
local Projectile = require "src.entities.projectile"
local ItemDrop = require "src.entities.itemdrop"
local Registry = require "src.registries"
local BLOCKS = Registry.blocks()

local Entities = Object {
    id = "entity",
    priority = 60,  -- After player (20), before interface
    all = {},
}

-- Entities type constants
Entities.TYPE_BULLET = "bullet"
Entities.TYPE_DROP = "drop"

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
function Entities.load(self)
    self.all = {}
    -- Initialize constants that depend on globals
    PICKUP_RANGE = BLOCK_SIZE
    Love.load(self)
end

-- Create a new entity with required components (position and velocity)
-- All entities have position and velocity Vectors
function Entities.newEntities(self, x, y, layer, vx, vy, entity_type, gravity, friction)
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
function Entities.newBullet(self, x, y, layer, vx, vy, width, height, color, gravity, destroys_blocks)
    local entity = self:newEntities(x, y, layer, vx, vy, Entities.TYPE_BULLET, gravity or BULLET_GRAVITY, BULLET_FRICTION)

    -- Add projectile component
    entity.bullet = Projectile.new(BULLET_DAMAGE, BULLET_LIFETIME, width, height, color, destroys_blocks)

    table.insert(self.all, entity)
    return entity
end

-- Spawn a drop entity
function Entities.newDrop(self, x, y, layer, block_id, count)
    -- Random horizontal velocity, upward initial velocity
    local vx = (math.random() - 0.5) * 50
    local vy = -50

    local entity = self:newEntities(x, y, layer, vx, vy, Entities.TYPE_DROP, DROP_GRAVITY, DROP_FRICTION)

    -- Add drop component
    entity.drop = ItemDrop.new(block_id, count, DROP_LIFETIME, DROP_PICKUP_DELAY)

    table.insert(self.all, entity)
    return entity
end

-- Get entities by type
function Entities.getByType(self, entity_type)
    local result = {}
    for _, ent in ipairs(self.all) do
        if ent.type == entity_type then
            table.insert(result, ent)
        end
    end
    return result
end

-- Remove an entity by id
function Entities.removeById(self, entity_id)
    for i = #self.all, 1, -1 do
        if self.all[i].id == entity_id then
            table.remove(self.all, i)
            return true
        end
    end
    return false
end

-- Update all entities
function Entities.update(self, dt)
    for i = #self.all, 1, -1 do
        local ent = self.all[i]
        if ent then -- might have despawn already
            -- Apply gravity to velocity (all entities have gravity)
            Physics.apply_gravity(ent.velocity, ent.gravity, dt)
            -- Apply velocity to position
            ent.position.x = ent.position.x + ent.velocity.x * dt
            ent.position.y = ent.position.y + ent.velocity.y * dt
            -- Call component updates via Object recursion
            -- This handles entity-specific logic (lifetime, collision, etc.)
            Love.update(ent, dt)
            -- Remove dead entities
            if (ent.bullet and ent.bullet.dead) or (ent.drop and ent.drop.dead) then
                table.remove(self.all, i)
            end
        end
    end
    -- Do NOT Love.update(self, dt)
end

-- Draw all entities
function Entities.draw(self)
    local camera_x, camera_y = G.camera:get_offset()

    for _, ent in ipairs(self.all) do
        if ent.type == Entities.TYPE_BULLET and ent.bullet then
            ent.bullet:draw(ent, camera_x, camera_y)
        elseif ent.type == Entities.TYPE_DROP and ent.drop then
            ent.drop:draw(ent, camera_x, camera_y)
        end
        Love.draw(ent)
    end
end

return Entities
