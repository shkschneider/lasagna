local CommandsRegistry = require "registries.commands"
local VectorComponent = require "components.vector"

CommandsRegistry:register({
    name = "teleport",
    description = "Teleports to location",
    execute = function(args)
        local x, y = args[1], args[2], args[3] or G.player.position.z
        if G.player.position then
            G.player.position = VectorComponent.new(x, y, z)
            if G.player.velocity then
                G.player.velocity = VectorComponent.new(0, 0)
            end
        end
        return true, "Teleported"
    end,
})
