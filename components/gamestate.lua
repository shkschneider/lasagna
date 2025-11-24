-- GameState Component
-- Manages game state transitions

local GameState = {}

-- State constants
GameState.BOOT = "boot"
GameState.LOAD = "load"
GameState.PLAY = "play"
GameState.PAUSE = "pause"
GameState.QUIT = "quit"

function GameState.new(state)
    return {
        current = state or GameState.BOOT,
    }
end

function GameState.tostring(self)
    return self.current
end

return GameState
