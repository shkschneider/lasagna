local Armor = {
    id = "armor",
    BAR_GAP = 10,
    BAR_WIDTH = 150,
    tostring = function(self)
        return string.format("%d%%", self.current)
    end,
}

function Armor.new(current, max)
    local health = {
        current = current or 0,
        max = max or 100,
    }
    return setmetatable(health, { __index = Armor })
end

-- Armor halfs the damage (upfront)
function Armor.hit(self, damage)
    if self.invincible then return end
    Log.debug(string.format("Armor: %d-%d/%d", self.current, damage, self.max))
    self.current = math.max(0, self.current - damage)
end

function Armor.update(self, dt) end

-- Draw armor bar UI
function Armor.draw(self)
    local bar_index = 1
    local screen_width = love.graphics.getDimensions()
    local bar_height = BLOCK_SIZE / 4
    local bar_width = Armor.BAR_WIDTH * (1.0 - bar_index * 0.25)
    local bar_x = screen_width - bar_width - Armor.BAR_GAP
    local bar_y = Armor.BAR_GAP + (bar_height + Armor.BAR_GAP) * bar_index

    -- Armor bar background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", bar_x, bar_y, bar_width, bar_height)

    -- Armor bar fill (fills from right, decreases to left)
    if self.max > 0 then
        local armor_percentage = self.current / self.max
        local fill_width = bar_width * armor_percentage
        local fill_x = bar_x + bar_width - fill_width

        -- Silver/gray color for armor
        love.graphics.setColor(0.7, 0.7, 0.8, 0.8)
        love.graphics.rectangle("fill", fill_x, bar_y, fill_width, bar_height)
    end
end

return Armor
