-- Game System
-- Manages overall game state, time scale, and coordinates other systems

local Object = require "core.object"
local Time = require "components.time"
local State = require "components.state"

LAYER_MIN = -1
LAYER_DEFAULT = 0
LAYER_MAX = 1

BLOCK_SIZE = 16
STACK_SIZE = 64

local Game = Object.new {
    priority = 0,
    state = State.new(State.BOOT),
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

function Game.load(self, seed, debug)
    self:newState(State.LOAD)
    Object.load(self, seed, debug)
    self:newState(State.PLAY)
end

function Game.update(self, dt)
    local start = love.timer.getTime()
    if self.time.paused then return end
    if self.player and self.player:is_dead() then return end
    dt = dt * self.time.scale
    Object.update(self, dt)
end

function Game.newState(self, state)
    assert(state)
    self.state = State.new(state)
    Log.debug(string.format("%f", love.timer.getTime()), "Game", string.upper(self.state:tostring()))
end

return Game
