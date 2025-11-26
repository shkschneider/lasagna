-- Stance component
-- Player stance states for movement and collision

local StanceComponent = {
    -- Stance constants
    STANDING = "standing",
    JUMPING = "jumping",
    FALLING = "falling",
}

function StanceComponent.new(initial_stance)
    local stance = {
        id = "stance",
        current = initial_stance or StanceComponent.STANDING,
        crouched = false,
        tostring = function(self)
            return tostring(self.current) .. ":" .. tostring(self.crouched)
        end
    }
    return setmetatable(stance, { __index = StanceComponent })
end

return StanceComponent
