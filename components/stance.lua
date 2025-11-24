-- Stance Component
-- Manages entity stance/state

local Stance = {}

-- Stance constants
Stance.STANDING = "standing"
Stance.JUMPING = "jumping"
Stance.FALLING = "falling"

function Stance.new(current)
    return {
        current = current or Stance.STANDING,
        crouched = false,
    }
end

return Stance
