local Object = require "core.object"
local TimeComponent = require "components.time"
local GameStateComponent = require "components.gamestate"

local Game = {
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
    entity = require("systems.entity"),  -- Unified entity manager (replaces bullet and drop)
    ui = require("systems.interface"),
    chat = require("systems.chat"),
    lore = require("systems.lore"),
    debug = require("systems.debug"),
    save = require("systems.save"),
}

function Game.switch(self, gamestate)
    assert(gamestate)
    self.state = GameStateComponent.new(gamestate)
    Log.debug(string.format("%f", love.timer.getTime()), "Game", string.upper(self.state:tostring()))
end

function Game.load(self, ...)
    G.debug.enabled = true
    self:switch(GameStateComponent.LOAD)
    Object.load(self, ...)
    self:switch(GameStateComponent.PLAY)
end

function Game.reload(self)
    local seed = G.world.worlddata.seed
    local debug = G.debug.enabled or false
    self = require "core.game"
    self:switch(GameStateComponent.LOAD)
    Object.load(self, seed, debug)
    self:switch(GameStateComponent.PLAY)
end

return Game
