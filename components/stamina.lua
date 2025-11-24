-- Stamina component
-- Stamina stored as 0-100 percentage

local Stamina = {}

function Stamina.new(current, max)
    return {
        id = "stamina",
        current = current or 100,
        max = max or 100,
        tostring = function(self)
            return string.format("%d%%", math.floor(self.current))
        end
    }
end

return Stamina
