local CommandsRegistry = require "src.registries.commands"

CommandsRegistry:register({
    name = "kill",
    description = "Kills an entity",
    execute = function(args)
        if not G.debug then return false, nil end
        G.player.health.current = 0
        return true, "Killed"
    end,
})
