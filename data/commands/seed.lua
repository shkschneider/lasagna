local CommandsRegistry = require "registries.commands"

CommandsRegistry:register({
    name = "seed",
    description = "Display the current world seed",
    execute = function(args)
        local seed = G.world.worlddata.seed
        return true, "World seed: " .. tostring(seed)
    end,
})
