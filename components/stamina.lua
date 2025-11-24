-- Stamina Component
-- Manages entity stamina

local Stamina = {}

function Stamina.new(current, max)
    return {
        current = current or 100,
        max = max or 100,
        tostring = function(self)
            return string.format("%d%%", self.current)
        end
    }
end

return Stamina
