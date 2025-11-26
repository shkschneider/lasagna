local GameStateComponent = {}
-- TODO not a component
GameStateComponent.__index = GameStateComponent

GameStateComponent.BOOT = "boot"
GameStateComponent.LOAD = "load"
GameStateComponent.MENU = "menu"
GameStateComponent.PLAY = "play"
GameStateComponent.PAUSE = "pause"
GameStateComponent.DEAD = "dead"
GameStateComponent.QUIT = "quit"

function GameStateComponent.new(state)
    return {
        id = "state",
        current = state,
        tostring = function(self)
            return string.upper(tostring(self.current))
        end
    }
end

return GameStateComponent
