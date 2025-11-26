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
                local save_data = G.save:load()
                if save_data then
                    G:load()
                    G.save:apply_save_data(save_data)
                end
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
