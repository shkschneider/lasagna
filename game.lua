-- Game System
-- Manages overall game state, time scale, and coordinates other systems

local log = require "lib.log"
local Systems = require "systems"
local TimeScale = require "components.timescale"
local GameState = require "components.gamestate"

LAYER_MIN = -1
LAYER_DEFAULT = 0
LAYER_MAX = 1

BLOCK_SIZE = 16
STACK_SIZE = 64

local Game = {
    priority = 0,
    components = {
        state = GameState.new(GameState.BOOT),
        timer = 0,
    },
    systems = {
        world = require("systems.world"),
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
    },
}

function Game.switch(self, gamestate)
    assert(gamestate)
    self.components.gamestate = GameState.new(gamestate)
    log.debug("Game", "switch:" .. self.components.gamestate:tostring())
end

function Game.load(self, seed, debug)
    -- Initialize components
    self:switch(GameState.LOAD)
    self.components.timescale = TimeScale.new(1, false)

    -- Load systems in specific order with correct parameters
    Systems.load(self.systems, seed, debug)

    -- Transition to playing state
    self:switch(GameState.PLAY)
end

function Game.update(self, dt)
    self.components.timer = self.components.timer + dt

    -- Check if paused
    if self.components.timescale.paused then
        return
    end

    -- Apply time scale
    dt = dt * self.components.timescale.scale

    -- Update all systems
    for _, system in Systems.iterate(self.systems) do
        if type(system.update) == "function" then
            system:update(dt)
        end
    end
end

function Game.draw(self)
    love.graphics.setDefaultFilter("nearest", "nearest")
    -- Draw all systems
    for _, system in Systems.iterate(self.systems) do
        if type(system.draw) == "function" then
            system:draw()
        end
    end
end

function Game.keypressed(self, key)
    -- Handle escape
    if key == "escape" then
        self:switch(GameState.QUIT)
        love.event.quit()
        return
    end

    if self.systems.debug and self.systems.debug.enabled then
        -- Time scale controls
        if key == "[" then
            self.components.timescale.scale = self.components.timescale.scale / 2
        elseif key == "]" then
            self.components.timescale.scale = self.components.timescale.scale * 2
        end
    end

    -- Pass to all systems
    for _, system in Systems.iterate(self.systems) do
        if type(system.keypressed) == "function" then
            system:keypressed(key)
        end
    end
end

function Game.keyreleased(self, key)
    -- Pass to all systems
    for _, system in Systems.iterate(self.systems) do
        if type(system.keyreleased) == "function" then
            system:keyreleased(key)
        end
    end
end

function Game.mousepressed(self, x, y, button)
    -- Pass to all systems
    for _, system in Systems.iterate(self.systems) do
        if type(system.mousepressed) == "function" then
            system:mousepressed(x, y, button)
        end
    end
end

function Game.mousereleased(self, x, y, button)
    -- Pass to all systems
    for _, system in Systems.iterate(self.systems) do
        if type(system.mousereleased) == "function" then
            system:mousereleased(x, y, button)
        end
    end
end

function Game.mousemoved(self, x, y, dx, dy)
    -- Pass to all systems
    for _, system in Systems.iterate(self.systems) do
        if type(system.mousemoved) == "function" then
            system:mousemoved(x, y, dx, dy)
        end
    end
end

function Game.wheelmoved(self, x, y)
    -- Pass to all systems
    for _, system in Systems.iterate(self.systems) do
        if type(system.wheelmoved) == "function" then
            system:wheelmoved(x, y)
        end
    end
end

function Game.textinput(self, text)
    -- Pass to all systems
    for _, system in Systems.iterate(self.systems) do
        if type(system.textinput) == "function" then
            system:textinput(text)
        end
    end
end

function Game.resize(self, width, height)
    -- Pass to all systems
    for _, system in Systems.iterate(self.systems) do
        if type(system.resize) == "function" then
            system:resize(width, height)
        end
    end
end

function Game.focus(self, focused)
    -- Pass to all systems
    for _, system in Systems.iterate(self.systems) do
        if type(system.focus) == "function" then
            system:focus(focused)
        end
    end
end

function Game.quit(self)
    -- Pass to all systems
    for _, system in Systems.iterate(self.systems) do
        if type(system.quit) == "function" then
            system:quit()
        end
    end
end

function Game.debug(self)
    return self.systems.debug and self.systems.debug.enabled == true
end

return Game
