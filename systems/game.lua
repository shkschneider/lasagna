-- Game System
-- Manages overall game state, time scale, and coordinates other systems

local GameState = require("components/gamestate")
local TimeScale = require("components/timescale")
local States = require("states")

local GameSystem = {
    priority = 0,
    components = {},
    systems = {}, -- Holds references to other systems
}

function GameSystem:load(seed, debug)
    -- Initialize components
    self.components.gamestate = GameState.new(States.BOOT, debug, seed)
    self.components.timescale = TimeScale.new(1, false)
    
    -- Transition to loading state
    self.components.gamestate.state = States.LOADING
end

function GameSystem:register_system(name, system)
    self.systems[name] = system
end

function GameSystem:get_system(name)
    return self.systems[name]
end

function GameSystem:update(dt)
    -- Apply time scale
    if not self.components.timescale.paused then
        dt = dt * self.components.timescale.scale
    else
        dt = 0
    end
    
    -- Store scaled dt for other systems to use
    self.scaled_dt = dt
    
    -- Transition to playing state if loading complete
    if self.components.gamestate.state == States.LOADING then
        self.components.gamestate.state = States.PLAYING
    end
end

function GameSystem:draw()
    -- Draw debug info
    if self.components.gamestate.debug then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(string.format("Seed: %s", self.components.gamestate.seed), 10, 120)
        love.graphics.print(string.format("Frames: %d/s", love.timer.getFPS()), 10, 100)
        love.graphics.print(string.format("TimeScale: %f", self.components.timescale.scale), 10, 140)
    end
end

function GameSystem:keypressed(key)
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
end

function GameSystem:get_scaled_dt()
    return self.scaled_dt or 0
end

function GameSystem:is_paused()
    return self.components.timescale.paused
end

function GameSystem:get_seed()
    return self.components.gamestate.seed
end

function GameSystem:is_debug()
    return self.components.gamestate.debug
end

return GameSystem
