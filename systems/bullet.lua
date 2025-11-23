-- Bullet System
-- Manages bullet entities (projectiles from weapons)

require "lib"

local Systems = require "systems"
local Position = require "components.position"
local Velocity = require "components.velocity"
local Bullet = require "components.bullet"

local BulletSystem = {
    id = "bullet",
    priority = 65,
    entities = {},
}

function BulletSystem.load(self)
    self.entities = {}
end

function BulletSystem.create_bullet(self, x, y, layer, vx, vy, width, height, color)
    local BULLET_DAMAGE = 10
    local BULLET_LIFETIME = 5
    
    local entity = {
        id = uuid(),
        position = Position.new(x, y, layer),
        velocity = Velocity.new(vx, vy),
        bullet = Bullet.new(BULLET_DAMAGE, BULLET_LIFETIME, width, height, color),
    }

    table.insert(self.entities, entity)

    return entity
end

function BulletSystem.update(self, dt)
    local world = Systems.get("world")

    for i = #self.entities, 1, -1 do
        local ent = self.entities[i]

        -- Update position
        ent.position.x = ent.position.x + ent.velocity.vx * dt
        ent.position.y = ent.position.y + ent.velocity.vy * dt

        -- Check collision with blocks
        local col, row = world:world_to_block(ent.position.x, ent.position.y)
        local block_def = world:get_block_def(ent.position.z, col, row)

        if block_def and block_def.solid then
            -- Bullet hit a block, remove it
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
