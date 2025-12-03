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

--  update method - handles bullet lifetime and collision
function Projectile.update(self, dt, entity)
    -- Decrease lifetime
    self.lifetime = self.lifetime - dt
    if self.lifetime <= 0 then
        self.dead = true
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
