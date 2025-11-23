local CommandsRegistry = require("registries.commands")
local Systems = require("systems")

-- Register /seed command
CommandsRegistry:register({
    name = "seed",
    description = "Display the current world seed",
    execute = function(args)
        local world = Systems.get("world")
        if world and world.components and world.components.worlddata then
            local seed = world.components.worlddata.seed
            return true, "World seed: " .. tostring(seed)
        end
        return false, "World not loaded"
    end,
})
