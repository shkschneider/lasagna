-- Layer Component
-- Manages layer state

local Layer = {}

function Layer.new(current_layer)
    return {
        current_layer = current_layer or 0,
    }
end

return Layer
