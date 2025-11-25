-- Health component
-- Health stored as 0-100 percentage

local Object = require "core.object"

local HealthComponent = Object.new {}

-- Constants
HealthComponent.DAMAGE_DISPLAY_DURATION = 0.5

function HealthComponent.new(current, max)
    local instance = {
        id = "health",
        priority = 50,  -- Components update in priority order
        current = current or 100,
        max = max or 100,
        invincible = false,
        regen_rate = 0,  -- Health per second (0 = no regen by default)
        damage_timer = 0,  -- Timer for visual damage effect
        tostring = function(self)
            return string.format("%d%%:%s", self.current, tostring(self.invincible))
        end
    }

    -- Assign update and draw methods to instance
    instance.update = HealthComponent.update
    instance.draw = HealthComponent.draw
    instance.hit = HealthComponent.hit
    instance.is_recently_damaged = HealthComponent.is_recently_damaged

    return instance
end

-- Apply damage to health
function HealthComponent.hit(self, damage)
    if self.invincible then
        return
    end

    -- Apply damage
    self.current = math.max(0, self.current - damage)

    -- Set damage timer for visual effect
    self.damage_timer = HealthComponent.DAMAGE_DISPLAY_DURATION
end

-- Check if recently damaged (for visual effects)
function HealthComponent.is_recently_damaged(self)
    return self.damage_timer > 0
end

-- Component update method - called automatically by Object recursion
function HealthComponent.update(self, dt)
    -- Update damage timer
    if self.damage_timer > 0 then
        self.damage_timer = self.damage_timer - dt
    end

    -- Health regeneration (if enabled)
    if self.regen_rate > 0 and self.current < self.max then
        self.current = math.min(self.max, self.current + self.regen_rate * dt)
    end
end

-- Component draw method - draws health bar UI
function HealthComponent.draw(self)
    -- Get screen dimensions
    local screen_width, screen_height = love.graphics.getDimensions()

    -- Get hotbar to position health bar relative to it
    if not G.player or not G.player.hotbar then return end
    local hotbar = G.player.hotbar

    -- Calculate hotbar position
    local slot_size = 60
    local hotbar_y = screen_height - 80
    local hotbar_x = (screen_width - (hotbar.size * slot_size)) / 2
    local hotbar_width = hotbar.size * slot_size

    -- Health bar dimensions and position
    local health_bar_height = BLOCK_SIZE / 4  -- 1/4 BLOCK_SIZE high
    local health_bar_width = hotbar_width / 2  -- Half the hotbar width
    local health_bar_x = hotbar_x  -- Aligned left
    local health_bar_y = hotbar_y - health_bar_height - 10  -- 10px above hotbar

    -- Health bar background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", health_bar_x, health_bar_y, health_bar_width, health_bar_height)

    -- Health bar fill
    local health_percentage = self.current / self.max
    local health_fill_width = health_bar_width * health_percentage

    -- Color based on health percentage
    if health_percentage > 0.6 then
        love.graphics.setColor(0, 1, 0, 0.8)  -- Green
    elseif health_percentage > 0.3 then
        love.graphics.setColor(1, 1, 0, 0.8)  -- Yellow
    else
        love.graphics.setColor(1, 0, 0, 0.8)  -- Red
    end
    love.graphics.rectangle("fill", health_bar_x, health_bar_y, health_fill_width, health_bar_height)
end

return HealthComponent
