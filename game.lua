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
    self.gamestate = GameState.new(gamestate)
    log.debug(string.format("%f", love.timer.getTime()), "Game", "switch:" .. self.gamestate:tostring())
end

function Game.load(self, seed, debug)
    self:switch(GameState.LOAD)
    self.timescale = TimeScale.new(1, false)
    -- TODO sort
    Systems.load(self, seed, debug)
    -- self.world:load(seed, debug)
    -- self.player:load()
    -- self.mining:load()
    -- self.building:load()
    -- self.weapon:load()
    -- self.bullet:load()
    -- self.drop:load()
    -- self.camera:load()
    -- self.ui:load()
    -- self.chat:load()
    -- self.lore:load()
    -- self.debug:load(seed, debug)
    log.debug("All systems operational.")
    self:switch(GameState.PLAY)
end

function Game.update(self, dt)
    if self.timescale.paused then return end
    if self.player and self.player:is_dead() then return end
    dt = dt * self.timescale.scale
    Object.update(self, dt)
end

function Game.draw(self)
    love.graphics.setDefaultFilter("nearest", "nearest")
    Object.draw(self)
end

function Game.keypressed(self, key)
    if key == "escape" then
        self:switch(GameState.QUIT)
        love.event.quit()
        return
    end
    if self.debug and self.debug.enabled then
        if key == "[" then
            self.timescale.scale = self.timescale.scale / 2
        elseif key == "]" then
            self.timescale.scale = self.timescale.scale * 2
        end
    end
    Object.keypressed(self, key)
end

function Game.keyreleased(self, key)
    Object.keyreleased(self, key)
end

function Game.mousepressed(self, x, y, button)
    Object.mousepressed(self, x, y, button)
end

function Game.mousereleased(self, x, y, button)
    Object.mouserelease(self, x, y, button)
end

function Game.mousemoved(self, x, y, dx, dy)
    Object.mousemoved(self, x, y, dx, dy)
end

function Game.wheelmoved(self, x, y)
    Object.wheelmoved(self, x, y)
end

function Game.textinput(self, text)
    Object.textinput(self, text)
end

function Game.resize(self, width, height)
    Object.resize(self, width, height)
end

function Game.focus(self, focused)
    Object.focus(self, focused)
end

function Game.quit(self)
    Object.quit(self, focus)
end

function Game.is_debug(self)
    return self.debug and self.debug.enabled == true
end

return Game
