local Love = require "core.love"
local Object = require "core.object"
local TimeComponent = require "components.time"
local GameStateComponent = require "components.gamestate"
local Shaders = require "libraries.shaders"

local Game = Object {
    id = "game",
    priority = 0,
    state = GameStateComponent.new(GameStateComponent.BOOT),
    time = TimeComponent.new(1),
    world = require("systems.world"),
    camera = require("systems.ui.camera"),
    player = require("systems.entities.player"),
    mining = require("systems.mining"),
    building = require("systems.building"),
    weapon = require("systems.weapon"),
    entity = require("systems.entities"),
    ui = require("systems.ui"),
    chat = require("systems.chat"),
    lore = require("systems.lore"),
    menu = require("systems.menu"),
    loader = require("systems.ui.loader"),
    canvases = nil,
}

function Game.switch(self, gamestate)
    assert(gamestate)
    self.state = GameStateComponent.new(gamestate)
    Log.debug(string.format("%f", love.timer.getTime()), "Game", string.upper(self.state:tostring()))
    G.menu:load()
end

function Game.load(self)
    self:switch(GameStateComponent.LOAD)
    Love.load(self)
    self:switch(GameStateComponent.PLAY)
end

local function render(canvas, ...)
    local objects = {...}
    canvas:renderTo(function()
        love.graphics.clear(0, 0, 0, 0)
        for _, c in ipairs(objects) do
            if type(c.draw) == "function" then
                c:draw()
            end
        end
    end)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canvas)
end

function Game.draw(self)
    if not self.canvases then
        local width, height = love.graphics.getDimensions()
        self.canvases = {
            world = love.graphics.newCanvas(width, height),
            things = love.graphics.newCanvas(width, height),
            overlay = love.graphics.newCanvas(width, height),
        }
    end
    if self.state.current == GameStateComponent.MENU or self.state.current == GameStateComponent.LOAD then
        love.graphics.setColor(0, 0, 0, 1)
        render(self.canvases.overlay, self.menu)
    else
        love.graphics.clear(0.4, 0.6, 0.9, 1)
        render(self.canvases.world, self.world)
        render(self.canvases.things, self.entity, self.player)
        render(self.canvases.overlay, self.ui, self.chat, self.state.current == GameStateComponent.PAUSE and self.menu or nil)
    end
end

function Game.resize(self, width, height)
    self.canvases = nil -- invalidates
end

return Game
