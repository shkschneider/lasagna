local GameState = {
    id = "state",
    BOOT = "boot",
    LOAD = "load",
    MENU = "menu",
    PLAY = "play",
    PAUSE = "pause",
    DEAD = "dead",
    QUIT = "quit",
    tostring = function(self)
        return string.upper(tostring(self.current))
    end,
}

function GameState.new(state)
    local gamestate = {
        current = state,
    }
    return setmetatable(gamestate, { __index = GameState })
end

function GameState.tostring_state(state)
    return string.upper(tostring(state))
end

return GameState
