local GameState = require "src.game.state"

return function()
    local save_exists = G.world.save:exists()
    return {
        {
            key = "l",
            label = "[L] oad Game",
            enabled = save_exists,
            action = function()
                G.pending_save_data = G.world.save:rollback()
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
