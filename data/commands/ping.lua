local CommandsRegistry = require "src.registries.commands"

CommandsRegistry:register({
    name = "ping",
    description = "Ping-Pong",
    execute = function(args)
        return true, "pong"
    end,
})
