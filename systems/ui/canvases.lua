local Love = require "core.love"
local Object = require "core.object"

local CanvasSystem = Object {
    id = "canvases",
    priority = 0,  -- Lowest priority - initialized first
    COUNT = 7,
}

-- Initialize all canvases
function CanvasSystem.load(self)
    self:create_canvases()
    Love.load(self)
end

-- Create all game canvases
function CanvasSystem.create_canvases(self)
    local screen_width, screen_height = love.graphics.getDimensions()

    -- Terrain layers (one canvas per layer: -1, 0, 1)
    self.layers = {
        [-1] = love.graphics.newCanvas(screen_width, screen_height),
        [0] = love.graphics.newCanvas(screen_width, screen_height),
        [1] = love.graphics.newCanvas(screen_width, screen_height),
    }

    -- Player canvas
    self.player = love.graphics.newCanvas(screen_width, screen_height)

    -- Entities/miscellaneous canvas (drops, bullets, etc.)
    self.entities = love.graphics.newCanvas(screen_width, screen_height)

    -- UI canvas (text overlay, HUD, hotbar)
    self.ui = love.graphics.newCanvas(screen_width, screen_height)

    -- Menu canvas (main menu, pause menu)
    self.menu = love.graphics.newCanvas(screen_width, screen_height)
end

-- Handle window resize - recreate all canvases with new dimensions
function CanvasSystem.resize(self, width, height)
    self:create_canvases()
    Love.resize(self, width, height)
end

return CanvasSystem
