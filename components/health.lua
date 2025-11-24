-- Health component
-- Health stored as 0-100 percentage

local Health = {}

function Health.new(current, max)
    return {
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
end

-- Component update method - called automatically by Object recursion
function Health.update(self, dt)
    -- Health regeneration (if enabled)
    if self.regen_rate > 0 and self.current < self.max then
        self.current = math.min(self.max, self.current + self.regen_rate * dt)
    end
end

-- Component draw method - for health overlays/effects
function Health.draw(self)
    -- Optional: can be used for visual health effects
    -- Default implementation does nothing
end

return Health
