local Love = require "core.love"
local Object = require "core.object"
local TimeComponent = require "components.time"
local GameStateComponent = require "components.gamestate"

local Game = Object {
    id = "game",
    priority = 0,
    state = nil,
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
    renderer = require("systems.ui.renderer"),
}

function Game.switch(self, gamestate)
    assert(gamestate)
    Log.debug(string.upper(gamestate))
    self.state = GameStateComponent.new(gamestate)
    G.menu:load()
end

function Game.load(self)
    self.state = GameStateComponent.new(GameStateComponent.BOOT)
    self.renderer:load()
    self.state = GameStateComponent.new(GameStateComponent.MENU)
    self.menu:load()
end

function Game.update(self, dt)
    if self.state.current == GameStateComponent.BOOT then
        return -- wait
    elseif self.state.current == GameStateComponent.LOAD then
        self.menu:update(dt) -- progress
    else
        Love.update(self, dt)
    end
end

function Game.draw(self)
    self.renderer:draw() -- NOT Love.draw
end

return Game
