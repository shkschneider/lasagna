local GameStateComponent = require "components.gamestate"

return function()
    local save_exists = G.save:exists()
    return {
        {
            key = "c",
            label = "[C] ontinue",
            enabled = save_exists,
            action = function()
                -- Store save data for loading phase
                G.pending_save_data = G.save:load()
                -- Transition to LOADING state
                G:switch(GameStateComponent.LOADING)
            end
        },
        {
            key = "n",
            label = "[N] ew Game",
            enabled = true,
            action = function()
                -- Clear any pending save data
                G.pending_save_data = nil
                -- Transition to LOADING state
                G:switch(GameStateComponent.LOADING)
            end
        },
        {
            key = "q",
            label = "[Q] uit",
            enabled = true,
            action = function()
                G:switch(GameStateComponent.QUIT)
                love.event.quit()
            end
        },
    }
end
