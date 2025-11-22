-- GameState component
-- Game state data

local GameState = {}

function GameState.new(state, debug, seed)
    return {
        state = state or "BOOT",
        debug = debug or false,
        seed = seed or os.time(),
    }
end

return GameState
