local Shaders = require "libraries.shaders"
local Object = require "core.object"
local GameState = require "src.data.gamestate"

local Renderer = Object {
    id = "renderer",
    priority = 1,  -- Very high priority - must initialize graphics first
    canvases = nil,
}

function Renderer.load(self)
    love.graphics.setDefaultFilter("nearest", "nearest")
    require("data.fonts"):load(function(fonts) fonts:set(fonts.Regular) end)
    self:resize(love.graphics.getDimensions())
end

local function render(canvas, ...)
    local objects = {...}
    canvas:renderTo(function()
        love.graphics.clear(0, 0, 0, 0)
        for _, c in ipairs(objects) do
            if type(c) == "function" then
                c()
            elseif type(c) == "table" and type(c.draw) == "function" then
                c:draw()
            end
        end
    end)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canvas)
end

function Renderer.draw(self)
    if not self.canvases then
        self:load()
    end
    local state = G.state.current
    if state == GameState.MENU or state == GameState.LOAD then
        love.graphics.setColor(0, 0, 0, 1)
        render(self.canvases.overlay, G.menu, G.loader)
    else
        love.graphics.clear(0.4, 0.6, 0.9, 1)
        local px, py, pz = G.player:get_position()
        -- love.graphics.setShader(Shaders.sepia)
        -- render(self.canvases.world1, function()
        --     for z = LAYER_MIN, pz - 1 do
        --         G.world:draw_layer(z)
        --     end
        -- end)
        -- love.graphics.setShader()
        render(self.canvases.world2, function()
            G.world:draw_layer(pz)
        end)
        render(self.canvases.entities, G.entities, G.player)
        -- love.graphics.setShader(Shaders.greyscale)
        -- render(self.canvases.world1, function()
        --     for z = pz + 1, LAYER_MAX do
        --         G.world:draw_layer(z)
        --     end
        -- end)
        -- love.graphics.setShader()
        render(self.canvases.things, G.mining, G.building, G.weapon, G.lore)
        render(self.canvases.overlay, G.ui, G.chat, G.debug or G.menu, G.debug and G.menu or nil)
    end
end

function Renderer.resize(self, width, height)
    self.canvases = {
        world1 = love.graphics.newCanvas(width, height),
        world2 = love.graphics.newCanvas(width, height),
        world3 = love.graphics.newCanvas(width, height),
        entities = love.graphics.newCanvas(width, height),
        things = love.graphics.newCanvas(width, height),
        overlay = love.graphics.newCanvas(width, height),
    }
end

return Renderer
