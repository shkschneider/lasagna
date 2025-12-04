local DrawUtils = require "src.world.draw_utils"

-- Local fallback function that uses shared drawing utility
local function draw(self, z)
    DrawUtils.draw_layer(self, z)
end

-- Delegate drawing to layer objects
function World.draw(self) end

function World.draw1(self, z)
    -- Background layers (behind player)
    if self.background_layer then
        for layer_z = LAYER_MIN, z - 1 do
            self.background_layer:draw_z(layer_z)
        end
    else
        -- Fallback if layers not initialized
        for layer_z = LAYER_MIN, z - 1 do
            draw(self, layer_z)
        end
    end
end

function World.draw2(self, z)
    -- Current player layer - rendered normally (no greyscale)
    -- Uses background_layer since it's rendered in the normal scene
    if self.background_layer then
        self.background_layer:draw_z(z)
    else
        -- Fallback if layers not initialized
        draw(self, z)
    end
end

function World.draw3(self, z)
    -- Foreground layers (in front of player)
    if self.foreground_layer then
        for layer_z = z + 1, LAYER_MAX do
            self.foreground_layer:draw_z(layer_z)
        end
    else
        -- Fallback if layers not initialized
        for layer_z = z + 1, LAYER_MAX do
            draw(self, layer_z)
        end
    end
end
