local Stance = {
    id = "stance",
    STANDING = "standing",
    JUMPING = "jumping",
    FALLING = "falling",
    tostring = function(self)
        return tostring(self.current) .. ":" .. tostring(self.crouched)
    end,
}

function Stance.new(initial_stance)
    local stance = {
        current = initial_stance or Stance.STANDING,
        crouched = false,
    }
    return setmetatable(stance, { __index = Stance })
end

return Stance
