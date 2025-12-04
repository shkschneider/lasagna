local CommandsRegistry = require "src.registries.commands"
local Vector = require "src.game.vector"

CommandsRegistry:register({
    name = "teleport",
    description = "Teleports to location",
    execute = function(args)
        if not G.debug then return false, nil end
        local x, y = args[1], args[2], args[3] or G.player.position.z
        G.player.position = Vector.new(x, y, z)
        G.player.velocity = Vector.new(0, 0)
        return true, "Teleported"
    end,
})
