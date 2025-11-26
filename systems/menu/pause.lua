local GameStateComponent = require "components.gamestate"

return function()
    local save_exists = G.save:exists()
    return {
        {
            key = "c",
            label = "[C] ontinue",
            enabled = true,
            action = function()
                G:switch(GameStateComponent.PLAY)
            end
        },
        {
            key = "s",
            label = "[S] ave Game",
            enabled = true,
            action = function()
                G.save:save()
                G:switch(GameStateComponent.PLAY)
            end
        },
        {
            key = "l",
            label = "[L] oad Game",
            enabled = save_exists,
            action = function()
                -- Store save data for loading phase
                G.pending_save_data = G.save:load()
                -- Transition to LOADING state
                G:switch(GameStateComponent.LOADING)
            end
        },
        {
            key = "q",
            label = "[Q] uit",
            enabled = true,
            action = function()
                -- TODO save
                G:switch(GameStateComponent.MENU)
            end
        },
    }
end
