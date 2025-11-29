local CommandsRegistry = require "src.registries.commands"

CommandsRegistry:register({
    name = "seed",
    description = "Display the current world seed",
    execute = function(args)
        local seed = G.world.generator.data.seed
        return true, "World seed: " .. tostring(seed)
    end,
})
