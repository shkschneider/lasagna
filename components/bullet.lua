-- Bullet component
-- Projectile data

local Bullet = {}

function Bullet.new(damage, speed, lifetime, width, height, color)
    return {
        id = "bullet",
        damage = damage or 10,
        speed = speed or 300,
        lifetime = lifetime or 5,
        width = width or 2,
        height = height or 2,
        color = color or {1, 1, 0, 1},  -- yellow by default
    }
end

return Bullet
