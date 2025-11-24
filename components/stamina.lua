-- Stamina component
-- Stamina stored as 0-100 percentage

local Object = require "core.object"

local Stamina = Object.new {}

function Stamina.new(current, max, regen_rate)
    local instance = {
        id = "stamina",
        priority = 51,  -- Components update in priority order
        current = current or 100,
        max = max or 100,
        regen_rate = regen_rate or 1,  -- Stamina per second
        tostring = function(self)
            return string.format("%d%%", math.floor(self.current))
        end
    }

    -- Assign update and draw methods to instance
    instance.update = Stamina.update
    instance.draw = Stamina.draw

    return instance
end

-- Component update method - called automatically by Object recursion
function Stamina.update(self, dt)
    -- Stamina regeneration
    if self.current < self.max then
        self.current = math.min(self.max, self.current + self.regen_rate * dt)
    end
end

-- Component draw method - draws stamina bar UI
function Stamina.draw(self)
    -- Get screen dimensions
    local screen_width, screen_height = love.graphics.getDimensions()

    -- Get inventory to position stamina bar relative to hotbar
    if not G.player or not G.player.inventory then return end
    local inv = G.player.inventory

    -- Calculate hotbar position
    local slot_size = 60
    local hotbar_y = screen_height - 80
    local hotbar_x = (screen_width - (inv.hotbar_size * slot_size)) / 2
    local hotbar_width = inv.hotbar_size * slot_size

    -- Stamina bar dimensions and position (right side, after health bar)
    local stamina_bar_height = BLOCK_SIZE / 4  -- 1/4 BLOCK_SIZE high
    local stamina_bar_width = hotbar_width / 2  -- Half the hotbar width
    local stamina_bar_x = hotbar_x + hotbar_width / 2  -- Aligned right (after health bar)
    local stamina_bar_y = hotbar_y - stamina_bar_height - 10  -- 10px above hotbar

    -- Stamina bar background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", stamina_bar_x, stamina_bar_y, stamina_bar_width, stamina_bar_height)

    -- Stamina bar fill
    local stamina_percentage = self.current / self.max
    local stamina_fill_width = stamina_bar_width * stamina_percentage

    -- Blue color for stamina
    love.graphics.setColor(0, 0.5, 1, 0.8)  -- Blue
    love.graphics.rectangle("fill", stamina_bar_x, stamina_bar_y, stamina_fill_width, stamina_bar_height)
end

return Stamina
