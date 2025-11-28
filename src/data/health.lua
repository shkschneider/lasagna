local Health = {
    id = "health",
    DAMAGE_DISPLAY_DURATION = 0.5,
    tostring = function(self)
        return string.format("%d%%:%s", self.current, tostring(self.invincible))
    end,
}

function Health.new(current, max)
    local health = {
        current = current or 100,
        max = max or 100,
        invincible = false,
        regen_rate = 0,  -- Health per second (0 = no regen by default)
        damage_timer = 0,  -- Timer for visual damage effect
    }
    return setmetatable(health, { __index = Health })
end

-- Apply damage to health
function Health.hit(self, damage)
    if self.invincible then
        return
    end

    -- Apply damage
    self.current = math.max(0, self.current - damage)

    -- Set damage timer for visual effect
    self.damage_timer = Health.DAMAGE_DISPLAY_DURATION
end

-- Check if recently damaged (for visual effects)
function Health.is_recently_damaged(self)
    return self.damage_timer > 0
end

-- Update health state
function Health.update(self, dt)
    -- Update damage timer
    if self.damage_timer > 0 then
        self.damage_timer = self.damage_timer - dt
    end

    -- Health regeneration (if enabled)
    if self.regen_rate > 0 and self.current < self.max then
        self.current = math.min(self.max, self.current + self.regen_rate * dt)
    end
end

return Health
