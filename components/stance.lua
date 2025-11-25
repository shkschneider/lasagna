-- Stance component
-- Player stance states for movement and collision

local StanceComponent = {}

-- Stance constants
StanceComponent.STANDING = "standing"
StanceComponent.JUMPING = "jumping"
StanceComponent.FALLING = "falling"

function StanceComponent.new(initial_stance)
    return {
        id = "stance",
        current = initial_stance or StanceComponent.STANDING,
        crouched = false,
        tostring = function(self)
            return tostring(self.current) .. ":" .. tostring(self.crouched)
        end
    }
end

return StanceComponent
