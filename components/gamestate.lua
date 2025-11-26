local GameStateComponent = {
    BOOT = "boot",
    LOAD = "load",
    MENU = "menu",
    PLAY = "play",
    PAUSE = "pause",
    DEAD = "dead",
    QUIT = "quit",
}

function GameStateComponent.new(state)
    local gamestate = {
        id = "state",
        current = state,
        tostring = function(self)
            return string.upper(tostring(self.current))
        end
    }
    return setmetatable(gamestate, { __index = GameStateComponent })
end

return GameStateComponent
