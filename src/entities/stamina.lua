local Stamina = {
    id = "stamina",
    BAR_GAP = 10,
    BAR_WIDTH = 150,
    tostring = function(self)
        return string.format("%d%%", math.floor(self.current))
    end,
}

function Stamina.new(current, max, regen_rate)
    local stamina = {
        current = current or 100,
        max = max or 100,
        regen_rate = regen_rate or 1,  -- Stamina per second
    }
    return setmetatable(stamina, { __index = Stamina })
end

-- Update stamina state
function Stamina.update(self, dt)
    -- Stamina regeneration
    if self.current < self.max then
        self.current = math.min(self.max, self.current + self.regen_rate * dt)
    end
end

-- Draw stamina bar UI
function Stamina.draw(self)
    local bar_index = 2
    local screen_width = love.graphics.getDimensions()
    local bar_height = BLOCK_SIZE / 4
    local bar_width = Stamina.BAR_WIDTH * (1.0 - bar_index * 0.25)
    local bar_x = screen_width - bar_width - Stamina.BAR_GAP
    local bar_y = Stamina.BAR_GAP + (bar_height + Stamina.BAR_GAP) * bar_index

    -- Stamina bar background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", bar_x, bar_y, bar_width, bar_height)

    -- Stamina bar fill (fills from right, decreases to left)
    local stamina_percentage = self.current / self.max
    local fill_width = bar_width * stamina_percentage
    local fill_x = bar_x + bar_width - fill_width

    -- Blue color for stamina
    love.graphics.setColor(0, 0.5, 1, 0.8)
    love.graphics.rectangle("fill", fill_x, bar_y, fill_width, bar_height)
end

return Stamina
