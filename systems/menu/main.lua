local GameStateComponent = require "components.gamestate"

return function()
    local save_exists = G.save:exists()
    return {
        {
            key = "c",
            label = "[C] ontinue",
            enabled = save_exists,
            action = function()
                -- Load save data first to get the seed
                local save_data = G.save:load()
                if save_data then
                    G:load()
                    G.save:apply_save_data(save_data)
                end
            end
        },
        {
            key = "n",
            label = "[N] ew Game",
            enabled = true,
            action = function()
                G:load()
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
