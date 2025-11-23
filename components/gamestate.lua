local GameState = {}

GameState.BOOT = "boot"
GameState.LOAD = "load"
GameState.PLAY = "play"
GameState.PAUSE = "pause"
GameState.DEAD = "dead"
GameState.QUIT = "quit"

function GameState.new(gamestate)
    return {
        id = "gamestate",
        current = gamestate,
        tostring = function(self)
            return tostring(self.current)
        end
    }
end

return GameState
