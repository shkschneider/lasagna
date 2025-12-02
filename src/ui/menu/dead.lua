local GameState = require "src.data.gamestate"

return function()
    return {
        {
            key = "return",
            label = "Press [ENTER] to respawn",
            enabled = true,
            action = function()
                -- Load the last save to respawn
                if G.world.save:exists() then
                    local save_data = G.world.save:rollback()
                    if save_data then
                        G.pending_save_data = save_data
                    end
                end
                G:load(GameState.LOAD)
            end
        },
    }
end
