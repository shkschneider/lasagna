local CommandsRegistry = require "src.registries.commands"
local GameState = require "src.data.gamestate"
local WorldData = require "src.data.worlddata"

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

        G.pending_save_data = save_data
        -- Reset the world with the saved seed
        G.world.generator.data = WorldData.new(save_data.seed)
        -- Trigger game reload which will apply save data via loader
        G:load(GameState.LOAD)

        return true, "Game loaded"
    end,
})
