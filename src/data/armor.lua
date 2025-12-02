local Armor = {
    id = "armor",
    DAMAGE_DISPLAY_DURATION = 0.5,
    tostring = function(self)
        return string.format("%d%%:%s", self.current, tostring(self.invincible))
    end,
}

function Armor.new(current, max)
    local armor = {
        current = current or 0,
        max = max or 100,
        invincible = false,
        regen_rate = 0,  -- Armor per second (0 = no regen by default)
        damage_timer = 0,  -- Timer for visual damage effect
    }
    return setmetatable(armor, { __index = Armor })
end

-- Apply damage to armor (armor takes half the damage that health would take)
-- Returns the remaining damage that should be applied to health
function Armor.hit(self, damage)
    if self.invincible or self.current <= 0 then
        return damage  -- No armor, all damage goes to health
    end

    -- Armor takes half the damage that health would take
    local armor_damage = damage / 2

    -- Calculate how much damage armor can absorb
    local absorbed = math.min(self.current, armor_damage)
    self.current = self.current - absorbed

    -- Set damage timer for visual effect
    if absorbed > 0 then
        self.damage_timer = Armor.DAMAGE_DISPLAY_DURATION
    end

    -- Return remaining damage for health (damage that wasn't absorbed by armor)
    -- If armor fully absorbed it, no damage to health
    if absorbed >= armor_damage then
        return 0
    else
        -- Armor was depleted, remaining damage goes to health
        -- The damage that wasn't absorbed = (armor_damage - absorbed) * 2
        -- Because armor takes half damage, health takes the full remainder
        return (armor_damage - absorbed) * 2
    end
end

-- Check if recently damaged (for visual effects)
function Armor.is_recently_damaged(self)
    return self.damage_timer > 0
end

-- Update armor state
function Armor.update(self, dt)
    -- Update damage timer
    if self.damage_timer > 0 then
        self.damage_timer = self.damage_timer - dt
    end

    -- Armor regeneration (if enabled)
    if self.regen_rate > 0 and self.current < self.max then
        self.current = math.min(self.max, self.current + self.regen_rate * dt)
    end
end

return Armor
