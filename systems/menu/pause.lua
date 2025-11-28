local GameStateComponent = require "components.gamestate"

return function()
    local save_exists = G.world.save:exists()
    return {
        {
            key = "c",
            label = "[C] ontinue",
            enabled = true,
            action = function()
                G:load(GameStateComponent.PLAY)
            end
        },
        {
            key = "s",
            label = "[S] ave Game",
            enabled = true,
            action = function()
                G.world.save:save()
                G:load(GameStateComponent.PLAY)
            end
        },
        {
            key = "l",
            label = "[L] oad Game",
            enabled = save_exists,
            action = function()
                G.pending_save_data = G.world.save:load()
                G:load(GameStateComponent.LOAD)
            end
        },
        {
            key = "q",
            label = "[Q] uit",
            enabled = true,
            action = function()
                G:load(GameStateComponent.MENU)
            end
        },
    }
end
