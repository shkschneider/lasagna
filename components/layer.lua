-- Layer component
-- Layer state information

local LayerComponent = {}

function LayerComponent.new(current_layer)
    return {
        id = "layer",
        current_layer = current_layer or 0,
    }
end

return LayerComponent
