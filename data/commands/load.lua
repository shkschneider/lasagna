local CommandsRegistry = require "src.registries.commands"
local GameState = require "src.data.gamestate"
local WorldData = require "src.data.worlddata"

-- Helper function to reload the game from save data
local function reload_from_save(save_data)
    -- Store save data for loader to apply after world regeneration
    G.pending_save_data = save_data

    -- Reset the world with the saved seed
    G.world.generator.data = WorldData.new(save_data.seed)

    -- Trigger game reload which will apply save data via loader
    G:load(GameState.LOAD)
end

CommandsRegistry:register({
    name = "load",
    description = "Load the last save",
    execute = function(args)
        -- Check if save exists
        if not G.world.save:exists() then
            return false, "No save to load"
        end

        -- Load save data
        local save_data = G.world.save:load()
        if not save_data then
            return false, "Failed to load save"
        end

        reload_from_save(save_data)
        return true, "Game loaded"
    end,
})
