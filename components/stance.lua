-- Stance component
-- Player stance states for movement and collision

local Stance = {}

-- Stance constants
Stance.STANDING = "standing"
Stance.JUMPING = "jumping"
Stance.FALLING = "falling"

function Stance.new(initial_stance)
    return {
        id = "stance",
        current = initial_stance or Stance.STANDING,
        crouched = false,
        tostring = function(self)
            return tostring(self.current) .. ":" .. tostring(self.crouched)
        end
    }
end

return Stance
