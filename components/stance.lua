-- Stance component
-- Manages player stance (standing, crouching)

local Stance = {
    id = "stance",
}

Stance.STANDING = "standing"
Stance.CROUCHING = "crouching"

function Stance.new(stance)
    return {
        id = "stance",
        current = stance or Stance.STANDING,
    }
end

return Stance
