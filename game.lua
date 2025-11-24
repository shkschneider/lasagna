-- Game System
-- Manages overall game state, time scale, and coordinates other systems

local log = require "lib.log"
local Object = require "core.object"
local Systems = require "systems"
local TimeScale = require "components.timescale"
local GameState = require "components.gamestate"

LAYER_MIN = -1
LAYER_DEFAULT = 0
LAYER_MAX = 1

BLOCK_SIZE = 16
STACK_SIZE = 64

local Game = Object.new {
    priority = 0,
    state = GameState.new(GameState.BOOT),
    timescale = TimeScale.new(1),
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

function Game.load(self, seed, debug)
    self:switch(GameState.LOAD)
    Object.load(self, seed, debug)
    log.debug("All systems operational.")
    self:switch(GameState.PLAY)
end

function Game.update(self, dt)
    if self.timescale.paused then return end
    if self.player and self.player:is_dead() then return end
    dt = dt * self.timescale.scale
    Object.update(self, dt)
end

function Game.switch(self, gamestate)
    assert(gamestate)
    self.gamestate = GameState.new(gamestate)
    log.debug(string.format("%f", love.timer.getTime()), "Game", string.upper(self.gamestate:tostring()))
end

return Game
