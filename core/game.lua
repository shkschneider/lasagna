local Object = require "core.object"
local Time = require "components.time"
local GameState = require "components.gamestate"

local Game = {
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
    ui = require("systems.interface"),
    chat = require("systems.chat"),
    lore = require("systems.lore"),
    debug = require("systems.debug"),
}

function Game.switch(self, gamestate)
    assert(gamestate)
    self.state = GameState.new(gamestate)
    Log.debug(string.format("%f", love.timer.getTime()), "Game", string.upper(self.state:tostring()))
end

function Game.load(self, ...)
    G.debug.enabled = true
    self:switch(GameState.LOAD)
    Object.load(self, ...)
    self:switch(GameState.PLAY)
end

function Game.reload(self)
    local seed = G.world.worlddata.seed
    local debug = G.debug.enabled or false
    self = require "core.game"
    self:switch(GameState.LOAD)
    Object.load(self, seed, debug)
    self:switch(GameState.PLAY)
end

return Game
