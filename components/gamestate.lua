local GameState = {}
GameState.__index = GameState

GameState.BOOT = "boot"
GameState.LOAD = "load"
GameState.PLAY = "play"
GameState.PAUSE = "pause"
GameState.DEAD = "dead"
GameState.QUIT = "quit"

function GameState.new(state)
    return {
        id = "state",
        current = state,
        tostring = function(self)
            return string.upper(tostring(self.current))
        end
    }
end

return GameState
