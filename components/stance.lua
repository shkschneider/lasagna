-- Stance component
-- Player stance states for movement and collision

local Stance = {}

-- Stance constants
Stance.STANDING = "standing"
Stance.JUMPING = "jumping"
Stance.FALLING = "falling"
Stance.CROUCHING = "crouching"

function Stance.new(initial_stance)
    return {
        id = "stance",
        current = initial_stance or Stance.STANDING,
    }
end

return Stance
