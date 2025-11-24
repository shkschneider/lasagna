-- Bullet System
-- Manages bullet entities (projectiles from weapons)

require "lib"

local Object = require "core.object"
local Bullet = require "components.bullet"

local BulletSystem = Object.new {
    id = "bullet",
    priority = 65,
    entities = {},
}

function BulletSystem.load(self)
    self.entities = {}
end

function BulletSystem.create_bullet(self, x, y, layer, vx, vy, width, height, color, gravity, destroys_blocks)
    local entity = Bullet.create_entity(x, y, layer, vx, vy, width, height, color, gravity, destroys_blocks)
    table.insert(self.entities, entity)
    return entity
end

function BulletSystem.update(self, dt)
    -- Update all bullet entities and remove marked ones
    for i = #self.entities, 1, -1 do
        local ent = self.entities[i]
        Object.update(ent, dt)
        
        -- Remove if marked for removal
        if ent.remove_me then
            table.remove(self.entities, i)
        end
    end
end

function BulletSystem.draw(self)
    -- Draw all bullet entities
    for _, ent in ipairs(self.entities) do
        Object.draw(ent)
    end
end

return BulletSystem
