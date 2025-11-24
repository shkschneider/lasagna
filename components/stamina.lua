-- Stamina component
-- Stamina stored as 0-100 percentage

local Stamina = {}

function Stamina.new(current, max, regen_rate)
    return {
        id = "stamina",
        priority = 51,  -- Components update in priority order
        current = current or 100,
        max = max or 100,
        regen_rate = regen_rate or 1,  -- Stamina per second
        tostring = function(self)
            return string.format("%d%%", math.floor(self.current))
        end
    }
end

-- Component update method - called automatically by Object recursion
function Stamina.update(self, dt)
    -- Stamina regeneration
    if self.current < self.max then
        self.current = math.min(self.max, self.current + self.regen_rate * dt)
    end
end

-- Component draw method - for stamina overlays/effects
function Stamina.draw(self)
    -- Optional: can be used for visual stamina effects
    -- Default implementation does nothing
end

return Stamina
