local Object = require "core.object"
local Registry = require "src.registries"
local BlockRef = require "data.blocks.ids"
local Biome = require "src.world.biome"

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
function Layer.draw_z(self, z)
    local world = self.world
    
    -- Get current screen dimensions dynamically
    local screen_width, screen_height = love.graphics.getDimensions()

    local camera_x, camera_y = G.camera:get_offset()

    -- Calculate visible area
    local start_col = math.floor(camera_x / BLOCK_SIZE) - 1
    local end_col = math.ceil((camera_x + screen_width) / BLOCK_SIZE) + 1
    local start_row = math.floor(camera_y / BLOCK_SIZE) - 1
    local end_row = math.ceil((camera_y + screen_height) / BLOCK_SIZE) + 1

    -- Clamp to world bounds (vertical only - horizontal is infinite)
    start_row = math.max(0, start_row)
    end_row = math.min(world.HEIGHT - 1, end_row)

    -- Draw blocks using actual block colors
    for col = start_col, end_col do
        for row = start_row, end_row do
            local value = world:get_block_value(z, col, row)

            local x = col * BLOCK_SIZE - camera_x
            local y = row * BLOCK_SIZE - camera_y

            -- value == 0 means SKY (fully transparent, don't draw)
            if value == BlockRef.SKY then
                -- Sky is fully transparent, nothing to draw
            elseif value == BlockRef.AIR then
                -- Underground air - draw semi-transparent black
            else
                -- Draw solid blocks
                local block_id = nil

                -- Check if it's a direct block ID (< NOISE_OFFSET) or a noise value (>= NOISE_OFFSET)
                if value < world.NOISE_OFFSET then
                    -- Direct block ID (grass, dirt, etc.)
                    block_id = value
                else
                    -- Noise value: convert back to 0.0-1.0 range and use shared weighted lookup
                    -- Shared underground distribution prevents visible seams at biome transitions
                    local noise_value = (value - world.NOISE_OFFSET) / 100
                    block_id = Biome.get_underground_block(noise_value)
                end

                if block_id then
                    local block = Registry.Blocks:get(block_id)
                    if block and block.color then
                        love.graphics.setColor(block.color[1], block.color[2], block.color[3], block.color[4] or 1)
                        love.graphics.rectangle("fill", x, y, BLOCK_SIZE, BLOCK_SIZE)
                    end
                end
            end
        end
    end
end

function Layer.draw(self)
    -- Default draw does nothing - specific layer types will override
end

return Layer
