local Object = require "core.object"
local Shaders = require "libraries.shaders"

local Canvases = Object {
    id = "canvases",
    priority = 200,  -- Very high priority - composites after all other systems draw
    -- Terrain layer canvases (indexed by layer: -1, 0, 1)
    terrain = {},
    -- Player canvas
    player = nil,
    -- Entities canvas (bullets, drops)
    entities = nil,
    -- UI canvas
    ui = nil,
}

-- Create all canvases with current screen dimensions
function Canvases.create(self)
    local screen_width, screen_height = love.graphics.getDimensions()

    -- Create terrain canvases for each layer
    self.terrain[-1] = love.graphics.newCanvas(screen_width, screen_height)
    self.terrain[0] = love.graphics.newCanvas(screen_width, screen_height)
    self.terrain[1] = love.graphics.newCanvas(screen_width, screen_height)

    -- Create player canvas
    self.player = love.graphics.newCanvas(screen_width, screen_height)

    -- Create entities canvas
    self.entities = love.graphics.newCanvas(screen_width, screen_height)

    -- Create UI canvas
    self.ui = love.graphics.newCanvas(screen_width, screen_height)
end

-- Draw function composites all canvases to the screen
function Canvases.draw(self)
    local player_x, player_y, player_z = G.player:get_position()

    -- Clear screen with sky blue background
    love.graphics.clear(0.4, 0.6, 0.9, 1)

    -- Set blend mode for proper layering
    love.graphics.setBlendMode("alpha", "premultiplied")

    -- Calculate max layer to render (from LAYER_MIN up to player_z + 1, clamped to LAYER_MAX)
    local max_layer = math.min(player_z + 1, LAYER_MAX)

    -- Draw terrain layers from LAYER_MIN to max_layer
    for layer = LAYER_MIN, max_layer do
        local canvas = self.terrain[layer]
        if canvas then
            if layer == player_z then
                -- Full color: player is on this layer
                love.graphics.setColor(1, 1, 1, 1)
            elseif layer == player_z + 1 then
                -- Full color: this is the layer above player (outlines already have alpha)
                love.graphics.setColor(1, 1, 1, 1)
            else
                -- Greyscale with dimming: layers behind player
                love.graphics.setShader(Shaders.greyscale)
                love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
            end
            love.graphics.draw(canvas, 0, 0)
            -- Reset shader after drawing layer behind player
            if layer < player_z then
                love.graphics.setShader()
            end
        end
    end

    -- Draw player canvas
    if self.player then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.player, 0, 0)
    end

    -- Draw entities canvas
    if self.entities then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.entities, 0, 0)
    end

    -- Draw UI canvas
    if self.ui then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.ui, 0, 0)
    end

    -- Reset blend mode to default
    love.graphics.setBlendMode("alpha")
end

return Canvases
