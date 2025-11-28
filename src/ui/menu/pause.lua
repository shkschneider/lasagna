local GameState = require "src.data.gamestate"

return function()
    local save_exists = G.world.save:exists()
    return {
        {
            key = "c",
            label = "[C] ontinue",
            enabled = true,
            action = function()
                G:load(GameState.PLAY)
            end
        },
        {
            key = "s",
            label = "[S] ave Game",
            enabled = true,
            action = function()
                G.world.save:save()
                G:load(GameState.PLAY)
            end
        },
        {
            key = "l",
            label = "[L] oad Game",
            enabled = save_exists,
            action = function()
                G.pending_save_data = G.world.save:load()
                G:load(GameState.LOAD)
            end
        },
        {
            key = "q",
            label = "[Q] uit",
            enabled = true,
            action = function()
                G:load(GameState.MENU)
            end
        },
    }
end
