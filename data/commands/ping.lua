local CommandsRegistry = require("registries.commands")

-- Register /ping command
CommandsRegistry:register({
    name = "ping",
    description = "Ping-Pong",
    execute = function(args)
        return true, "pong"
    end,
})
