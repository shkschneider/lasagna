-- Stamina component
-- Stamina stored as 0-100 percentage

local StaminaComponent = {}

function StaminaComponent.new(current, max, regen_rate)
    local stamina = {
        id = "stamina",
        current = current or 100,
        max = max or 100,
        regen_rate = regen_rate or 1,  -- Stamina per second
        tostring = function(self)
            return string.format("%d%%", math.floor(self.current))
        end
    }
    return setmetatable(stamina, { __index = StaminaComponent })
end

-- Update stamina state
function StaminaComponent.update(self, dt)
    -- Stamina regeneration
    if self.current < self.max then
        self.current = math.min(self.max, self.current + self.regen_rate * dt)
    end
end

return StaminaComponent
