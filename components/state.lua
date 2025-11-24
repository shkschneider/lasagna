local State = {}
State.__index = State

State.BOOT = "boot"
State.LOAD = "load"
State.PLAY = "play"
State.PAUSE = "pause"
State.DEAD = "dead"
State.QUIT = "quit"

function State.new(state)
    return {
        id = "state",
        current = state,
        tostring = function(self)
            return string.upper(tostring(self.current))
        end
    }
end

return State
