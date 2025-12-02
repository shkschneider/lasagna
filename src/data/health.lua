local Health = {
    id = "health",
    DAMAGE_DISPLAY_DURATION = 0.5,
    BAR_GAP = 10,
    BAR_WIDTH = 150,
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

    Log.debug(string.format("Health: %d-%d/%d", self.current, damage, self.max))

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

-- Draw health bar UI
function Health.draw(self)
    local bar_index = 0
    local screen_width = love.graphics.getDimensions()
    local bar_height = BLOCK_SIZE / 4
    local bar_width = Health.BAR_WIDTH
    local bar_x = screen_width - bar_width - Health.BAR_GAP
    local bar_y = Health.BAR_GAP + (bar_height + Health.BAR_GAP) * bar_index

    -- Health bar background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", bar_x, bar_y, bar_width, bar_height)

    -- Health bar fill (fills from right, decreases to left)
    local health_percentage = self.current / self.max
    local fill_width = bar_width * health_percentage
    local fill_x = bar_x + bar_width - fill_width

    -- Color based on health percentage
    if health_percentage > 0.6 then
        love.graphics.setColor(0, 1, 0, 0.8)  -- Green
    elseif health_percentage > 0.3 then
        love.graphics.setColor(1, 1, 0, 0.8)  -- Yellow
    else
        love.graphics.setColor(1, 0, 0, 0.8)  -- Red
    end
    love.graphics.rectangle("fill", fill_x, bar_y, fill_width, bar_height)
end

return Health
