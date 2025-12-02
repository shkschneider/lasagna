local Armor = {
    id = "armor",
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

return Armor
