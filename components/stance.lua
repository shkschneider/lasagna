-- Stance component
-- Manages player stance (standing, crouching, jumping)

local Stance = {
    id = "stance",
}

Stance.STANDING = "standing"
Stance.CROUCHING = "crouching"
Stance.JUMPING = "jumping"

function Stance.new(stance)
    return {
        id = "stance",
        current = stance or Stance.STANDING,
    }
end

-- Helper to check if on ground (not jumping)
function Stance.is_on_ground(stance)
    return stance.current ~= Stance.JUMPING
end

return Stance
