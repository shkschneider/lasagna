local CommandsRegistry = require "registries.commands"

CommandsRegistry:register({
    name = "kill",
    description = "Kills an entity",
    execute = function(args)
        G.player.health.current = 0
        return true, "Killed"
    end,
})
