-- Health component
-- Health stored as 0-100 percentage

local Object = require "core.object"

local Health = Object.new {}

function Health.new(current, max)
    local instance = {
        id = "health",
        priority = 50,  -- Components update in priority order
        current = current or 100,
        max = max or 100,
        invicible = false,
        regen_rate = 0,  -- Health per second (0 = no regen by default)
        tostring = function(self)
            return string.format("%d%%:%s", self.current, tostring(self.invicible))
        end
    }

    -- Assign update and draw methods to instance
    instance.update = Health.update
    instance.draw = Health.draw

    return instance
end

-- Component update method - called automatically by Object recursion
function Health.update(self, dt)
    -- Health regeneration (if enabled)
    if self.regen_rate > 0 and self.current < self.max then
        self.current = math.min(self.max, self.current + self.regen_rate * dt)
    end
end

-- Component draw method - draws health bar UI
function Health.draw(self)
    -- Get screen dimensions
    local screen_width, screen_height = love.graphics.getDimensions()

    -- Get inventory to position health bar relative to hotbar
    if not G.player or not G.player.inventory then return end
    local inv = G.player.inventory

    -- Calculate hotbar position
    local slot_size = 60
    local hotbar_y = screen_height - 80
    local hotbar_x = (screen_width - (inv.hotbar_size * slot_size)) / 2
    local hotbar_width = inv.hotbar_size * slot_size

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

return Health
