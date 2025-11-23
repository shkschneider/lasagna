-- Health component
-- Health stored as 0-100 percentage

local Health = {}

function Health.new(current, max)
    return {
        id = "health",
        current = current or 100,
        max = max or 100,
        invicible = false,
        tostring = function(self)
            return string.format("%d%%:%s", self.current, tostring(self.invicible))
        end
    }
end

return Health
