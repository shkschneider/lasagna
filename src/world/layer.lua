local Object = require "core.object"
local DrawUtils = require "src.world.draw_utils"

-- Layer represents a rendering layer in the world
-- 
-- The Layer object encapsulates the drawing logic for world blocks at different
-- z-levels. The World creates two Layer instances:
--   - background_layer: renders layers behind the player (draw1)
--   - foreground_layer: renders layers in front of the player (draw3)
-- 
-- Each Layer has:
--   - name: identifier string ("background" or "foreground")
--   - world: reference to the parent World object
--   - load/update/draw: standard Object lifecycle methods
--   - draw_z(z): draws all blocks in a specific z-layer
--
-- The Layer system allows for better organization of rendering logic and
-- makes it easier to add layer-specific effects or behaviors in the future.
local Layer = Object {
    id = "layer",
    priority = 10,
}

function Layer.new(name, world)
    local layer = Object {
        id = "layer:" .. name,
        priority = 10,
        name = name,
        world = world,
    }
    setmetatable(layer, { __index = Layer })
    return layer
end

function Layer.load(self)
    -- Layers don't need special loading logic for now
end

function Layer.update(self, dt)
    -- Layers don't need special update logic for now
end

-- Draw a single z-layer of blocks
-- Delegates to shared drawing utility for consistency
function Layer.draw_z(self, z)
    DrawUtils.draw_layer(self.world, z)
end

function Layer.draw(self)
    -- Base draw method - exists for Object pattern consistency but is currently unused.
    -- World.draw1/draw2/draw3 call draw_z() directly instead of relying on the
    -- standard Object draw() cascade, since they need to control which z-levels are drawn.
    -- This method is available for future use if layer-specific drawing is needed.
end

return Layer
