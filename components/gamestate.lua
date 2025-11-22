-- GameState component
-- Game state data

local GameState = {}

function GameState.new(state, debug, seed)
    return {
        id = "gamestate",
        state = state or "BOOT",
        debug = debug or false,
        seed = seed or os.time(),
        tostring = function()
            return string.format("%s:%d", state, seed)
        end
    }
end

return GameState
