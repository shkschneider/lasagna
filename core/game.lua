local Love = require "core.love"
local Object = require "core.object"
local TimeComponent = require "components.time"
local GameStateComponent = require "components.gamestate"

local Game = Object {
    id = "game",
    priority = 0,
    state = GameStateComponent.new(GameStateComponent.BOOT),
    time = TimeComponent.new(1),
    world = require("systems.world"),
    control = require("systems.control"),
    camera = require("systems.camera"),
    player = require("systems.player"),
    mining = require("systems.mining"),
    building = require("systems.building"),
    weapon = require("systems.weapon"),
    entity = require("systems.entity"),
    ui = require("systems.interface"),
    chat = require("systems.chat"),
    lore = require("systems.lore"),
    save = require("systems.save"),
    menu = require("systems.menu"),
}

function Game.switch(self, gamestate)
    assert(gamestate)
    self.state = GameStateComponent.new(gamestate)
    Log.debug(string.format("%f", love.timer.getTime()), "Game", string.upper(self.state:tostring()))
end

function Game.load(self)
    self:switch(GameStateComponent.LOAD)
    Love.load(self)
    self:switch(GameStateComponent.PLAY)
end

-- function Game.keypressed(self, key)
--     if key == "backspace" and not self.debug then
--         self.debug = require("systems.debug")
--         self.debug:load()
--     end
-- end

return Game
