-- Bullet component
-- Projectile data

local Bullet = {}

function Bullet.new(damage, lifetime, width, height, color, gravity, destroys_blocks)
    return {
        id = "bullet",
        damage = damage or 10,
        lifetime = lifetime or 5,
        width = width or 2,
        height = height or 2,
        color = color or {1, 1, 0, 1},  -- yellow by default
        gravity = gravity or 0,  -- gravity acceleration
        destroys_blocks = destroys_blocks or false,  -- whether bullet destroys blocks on impact
    }
end

return Bullet
