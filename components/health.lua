-- Health component
-- Health stored as 0-100 percentage

local Health = {}

function Health.new(current, max)
    return {
        id = "health",
        current = current or 100,
        max = max or 100,
    }
end

return Health
