-- GameState component

local GameState = {
    id = "gamestate",
}

GameState.BOOT = "boot"
GameState.LOAD = "load"
GameState.PLAY = "play"
GameState.PAUSE = "pause"
GameState.QUIT = "quit"

function GameState.new(gamestate)
    assert(gamestate)
    return {
        id = "gamestate",
        current = gamestate,
    }
end

return GameState
