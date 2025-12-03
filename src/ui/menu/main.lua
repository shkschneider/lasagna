local GameState = require "src.data.gamestate"

return function()
    local save_exists = G.world.save:exists()
    return {
        {
            key = "c",
            label = "[C] ontinue",
            enabled = save_exists,
            action = function()
                -- Store save data for loading phase
                G.pending_save_data = G.world.save:rollback()
                -- Transition to LOAD state
                G:load(GameState.LOAD)
            end
        },
        {
            key = "n",
            label = "[N] ew Game",
            enabled = true,
            action = function()
                -- Clear any pending save data
                G.pending_save_data = nil
                -- Transition to LOAD state
                G:load(GameState.LOAD)
            end
        },
        {
            key = "q",
            label = "[Q] uit",
            enabled = true,
            action = function()
                G:load(GameState.QUIT)
                love.event.quit()
            end
        },
    }
end
