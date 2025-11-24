local Object = require "core.object"
local Time = require "components.time"
local GameState = require "components.gamestate"

local Game = Object.new {
    priority = 0,
    state = GameState.new(GameState.BOOT),
    time = Time.new(1),
    world = require("systems.world"),
    control = require("systems.control"),
    camera = require("systems.camera"),
    player = require("systems.player"),
    mining = require("systems.mining"),
    building = require("systems.building"),
    weapon = require("systems.weapon"),
    bullet = require("systems.bullet"),
    drop = require("systems.drop"),
    ui = require("systems.ui"),
    chat = require("systems.chat"),
    debug = require("systems.debug"),
    lore = require("systems.lore"),
}

function Game.switch(self, gamestate)
    assert(gamestate)
    self.state = GameState.new(gamestate)
    Log.debug(string.format("%f", love.timer.getTime()), "Game", string.upper(self.state:tostring()))
end

function Game.reload(self)
    error("TODO")
end

return Game
