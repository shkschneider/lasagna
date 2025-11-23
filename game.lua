-- Game System
-- Manages overall game state, time scale, and coordinates other systems

local log = require "lib.log"
local Systems = require "systems"
local GameState = require "components.gamestate"
local TimeScale = require "components.timescale"

local Game = {
    priority = 0,
    components = {
        gamestate = GameState.new(GameState.BOOT),
    },
    systems = {
        world = require("systems.world"),
        camera = require("systems.camera"),
        player = require("systems.player"),
        mining = require("systems.mining"),
        building = require("systems.building"),
        drop = require("systems.drop"),
        ui = require("systems.ui"),
        debug = require("systems.debug"),
    },
}

function Game.load(self, seed, debug)
    -- Initialize components
    self.components.gamestate.current = GameState.LOAD
    log.info("Game", self.components.gamestate.current)
    self.components.timescale = TimeScale.new(1, false)

    -- Load systems in specific order with correct parameters
    Systems.load(self.systems, seed)

    if self:debug() then
        for id, system in pairs(self.systems) do
            assert(id == system.id, string.format("System %s != %s", id, system.id))
        end
        for id, component in pairs(self.components) do
            assert(id == component.id, string.format("Component %s != %s", id, component.id))
        end
    end

    -- Transition to playing state
    self.components.gamestate.current = GameState.PLAY
    log.info("Game", self.components.gamestate.current)
end

function Game.update(self, dt)
    -- Check if paused
    if self.components.gamestate.current == GameState.PAUSE then
        return
    end

    -- Apply time scale
    dt = dt * self.components.timescale.current

    -- Update all systems
    for _, system in Systems.iterate(self.systems) do
        if type(system.update) == "function" then
            system:update(dt)
        end
    end
end

function Game.draw(self)
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
        love.event.quit()
        return
    end

    if self.systems.debug and self.systems.debug.enabled then
        -- Time scale controls
        if key == "[" then
            self.components.timescale.current = self.components.timescale.current / 2
        elseif key == "]" then
            self.components.timescale.current = self.components.timescale.current * 2
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
