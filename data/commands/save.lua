local CommandsRegistry = require "src.game.registries.commands"

CommandsRegistry:register({
    name = "save",
    description = "Save the current game",
    execute = function(args)
        local success = G.world.save:save()
        if success then
            return true, "Game saved"
        else
            return false, "Failed to save game"
        end
    end,
})
