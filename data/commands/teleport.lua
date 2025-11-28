local CommandsRegistry = require "registries.commands"
local Vector = require "src.data.vector"

CommandsRegistry:register({
    name = "teleport",
    description = "Teleports to location",
    execute = function(args)
        if G.player.position then
            local x, y = args[1], args[2], args[3] or G.player.position.z
            G.player.position = Vector.new(x, y, z)
            G.player.velocity = Vector.new(0, 0)
        end
        return true, "Teleported"
    end,
})
