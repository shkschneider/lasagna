local CommandsRegistry = require "src.registries.commands"
local GameState = require "src.game.state"

CommandsRegistry:register({
    name = "load",
    description = "Load the last save",
    execute = function(args)
        -- Check if save exists
        if not G.world.save:exists() then
            return false, "No save to load"
        end

        -- Load save data
        local save_data = G.world.save:rollback()
        if not save_data then
            return false, "Failed to load save"
        end

        -- Store save data for loader to apply after world regeneration
        G.pending_save_data = save_data
        -- Trigger game reload which will apply save data via loader
        G:load(GameState.LOAD)

        return true, "Game loaded"
    end,
})
