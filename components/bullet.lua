-- Bullet component
-- Projectile data

local Bullet = {}

function Bullet.new(damage, lifetime, width, height, color, destroys_blocks)
    local instance = {
        id = "bullet",
        priority = 30,  -- Bullets update after velocity
        damage = damage or 10,
        lifetime = lifetime or 5,
        width = width or 2,
        height = height or 2,
        color = color or {1, 1, 0, 1},  -- yellow by default
        destroys_blocks = destroys_blocks or false,  -- whether bullet destroys blocks on impact
        enabled = true,
        dead = false,  -- Mark for removal
    }

    -- Assign update and draw methods to instance
    instance.update = Bullet.update
    instance.draw = Bullet.draw

    return instance
end

-- Component update method - handles bullet lifetime and collision
function Bullet.update(self, dt, entity)
    if not self.enabled then return end

    -- Decrease lifetime
    self.lifetime = self.lifetime - dt
    if self.lifetime <= 0 then
        self.dead = true
    end
end

-- Component draw method - renders bullet
function Bullet.draw(self, entity, camera_x, camera_y)
    if not self.enabled then return end

    if entity and entity.position then
        local x = entity.position.x - (camera_x or 0) - self.width / 2
        local y = entity.position.y - (camera_y or 0) - self.height / 2

        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill", x, y, self.width, self.height)
    end
end

return Bullet
