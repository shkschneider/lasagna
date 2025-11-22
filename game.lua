-- Game System
-- Manages overall game state, time scale, and coordinates other systems

local GameState = require("components.gamestate")
local TimeScale = require("components.timescale")
local States = require("core.states")

local Game = {
    priority = 0,
    components = {},
    systems = {
        world = require("systems.world"),
        player = require("systems.player"),
        camera = require("systems.camera"),
        mining = require("systems.mining"),
        drop = require("systems.drop"),
        render = require("systems.render"),
    },
}

function Game.world(self)
    return self.systems["world"]
end

function Game.player(self)
    return self.systems["player"]
end

function Game.load(self, seed, debug)
    -- Initialize components
    self.components.gamestate = GameState.new(States.BOOT, debug, seed)
    self.components.timescale = TimeScale.new(1, false)

    -- Transition to loading state
    self.components.gamestate.state = States.LOADING

    -- Load all registered systems
    for _, system in pairs(self.systems) do
        if type(system.load) == "function" then
            system.load(system, seed, debug)
        end
    end

    -- Transition to playing state
    self.components.gamestate.state = States.PLAYING

    -- Assertions
    for _, system in pairs(self.systems) do
        assert(type(system.id) == "string")
    end
end

function Game.get_system(self, name)
    return self.systems[name]
end

function Game.world(self)
    return self:get_system("world")
end

function Game.player(self)
    return self:get_system("player")
end

function Game.update(self, dt)
    -- Check if paused
    if self.components.timescale.paused then
        return
    end

    -- Apply time scale
    dt = dt * self.components.timescale.scale
    self.scaled_dt = dt

    -- Update all systems
    for _, system in pairs(self.systems) do
        if type(system.update) == "function" then
            system:update(dt)
        end
    end
end

function Game.draw(self)
    -- Draw all systems
    for _, system in pairs(self.systems) do
        if type(system.draw) == "function" then
            system:draw()
        end
    end

    -- Draw debug info last
    if self.components.gamestate.debug then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(string.format("Seed: %s", self.components.gamestate.seed), 10, 120)
        love.graphics.print(string.format("Frames: %d/s", love.timer.getFPS()), 10, 100)
        love.graphics.print(string.format("TimeScale: %f", self.components.timescale.scale), 10, 140)
    end
end

function Game.keypressed(self, key)
    -- Handle escape
    if key == "escape" then
        love.event.quit()
        return
    end

    -- Toggle debug mode
    if key == "backspace" then
        self.components.gamestate.debug = not self.components.gamestate.debug
    end

    -- Time scale controls (debug only)
    if self.components.gamestate.debug then
        if key == "[" then
            self.components.timescale.scale = self.components.timescale.scale / 2
        elseif key == "]" then
            self.components.timescale.scale = self.components.timescale.scale * 2
        end
    end

    -- Pass to all systems
    for _, system in pairs(self.systems) do
        if type(system.keypressed) == "function" then
            system.keypressed(system, key)
        end
    end
end

function Game.keyreleased(self, key)
    -- Pass to all systems
    for _, system in pairs(self.systems) do
        if type(system.keyreleased) == "function" then
            system.keyreleased(system, key)
        end
    end
end

function Game.mousepressed(self, x, y, button)
    -- Pass to all systems
    for _, system in pairs(self.systems) do
        if type(system.mousepressed) == "function" then
            system.mousepressed(system, x, y, button)
        end
    end
end

function Game.mousereleased(self, x, y, button)
    -- Pass to all systems
    for _, system in pairs(self.systems) do
        if type(system.mousereleased) == "function" then
            system.mousereleased(system, x, y, button)
        end
    end
end

function Game.mousemoved(self, x, y, dx, dy)
    -- Pass to all systems
    for _, system in pairs(self.systems) do
        if type(system.mousemoved) == "function" then
            system.mousemoved(system, x, y, dx, dy)
        end
    end
end

function Game.wheelmoved(self, x, y)
    -- Pass to all systems
    for _, system in pairs(self.systems) do
        if type(system.wheelmoved) == "function" then
            system.wheelmoved(system, x, y)
        end
    end
end

function Game.resize(self, width, height)
    -- Pass to all systems
    for _, system in pairs(self.systems) do
        if type(system.resize) == "function" then
            system.resize(system, width, height)
        end
    end
end

function Game.focus(self, focused)
    -- Pass to all systems
    for _, system in pairs(self.systems) do
        if type(system.focus) == "function" then
            system.focus(system, focused)
        end
    end
end

function Game.quit(self)
    -- Pass to all systems
    for _, system in pairs(self.systems) do
        if type(system.quit) == "function" then
            system.quit(system)
        end
    end
end

function Game.get_scaled_dt(self)
    return self.scaled_dt or 0
end

function Game.is_paused(self)
    return self.components.timescale.paused
end

function Game.get_seed(self)
    return self.components.gamestate.seed
end

function Game.is_debug(self)
    return self.components.gamestate.debug
end

return Game
