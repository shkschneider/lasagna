local CommandsRegistry = require "registries.commands"
local WorldData = require "src.data.worlddata"

CommandsRegistry:register({
    name = "reset",
    description = "Reset game (optional seed)",
    execute = function(args)
        local seed = tonumber(args[1] or (os.time() + love.timer.getTime()))
        G.world.generator.data = WorldData.new(seed)
        G:load()
        return true, "Reset (" .. seed .. ")"
    end,
})
