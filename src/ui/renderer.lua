local Shaders = require "libs.shaders"
local Object = require "core.object"
local GameState = require "src.game.state"

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

local function render(canvas, shader, ...)
    assert(type(shader) == "userdata" or type(shader) == "table")
    local objects = {...}
    if type(shader) == "userdata" then
        love.graphics.setShader(shader)
    end
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
    love.graphics.setShader()
end

function Renderer.draw(self)
    if not self.canvases then
        self:load()
    end
    local state = G.state.current
    if state == GameState.MENU or state == GameState.LOAD then
        love.graphics.setColor(0, 0, 0, 1)
        render(self.canvases.overlay, {}, G.menu, G.loader)
    else
        love.graphics.clear(0, 0, 0, 1)
        local _, _, pz = G.player:get_position()
        render(self.canvases.world1, Shaders.sepia,
            function() G.world:draw1(pz) end)
        render(self.canvases.world2, {},
            function() G.world:draw2(pz) end)
        render(self.canvases.entities, {},
            G.entities, G.player)
        render(self.canvases.world3, Shaders.greyscale,
            function() G.world:draw3(pz) end)
        render(self.canvases.things, {},
            G.mining, G.building, G.weapon, G.lore)
        render(self.canvases.overlay, {},
            G.ui, G.chat, G.debug or G.menu, G.debug and G.menu or nil)
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
