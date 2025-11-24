-- Health Component
-- Manages entity health

local Health = {}

function Health.new(current, max)
    return {
        current = current or 100,
        max = max or 100,
        invincible = false,
        tostring = function(self)
            return string.format("%d%%", self.current)
        end
    }
end

return Health
