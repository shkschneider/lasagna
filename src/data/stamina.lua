local Stamina = {
    id = "stamina",
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

return Stamina
