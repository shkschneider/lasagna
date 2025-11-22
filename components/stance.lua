-- Stance component
-- Manages player stance (standing, crouching, jumping, falling)

local Stance = {
    id = "stance",
}

Stance.STANDING = "standing"
Stance.CROUCHING = "crouching"
Stance.JUMPING = "jumping"
Stance.FALLING = "falling"

function Stance.new(stance)
    return {
        id = "stance",
        current = stance or Stance.STANDING,
    }
end

-- Helper to check if on ground (not jumping or falling)
function Stance.is_on_ground(stance)
    return stance.current ~= Stance.JUMPING and stance.current ~= Stance.FALLING
end

return Stance
