local CommandsRegistry = require "registries.commands"
local WorldDataComponent = require "components.worlddata"

CommandsRegistry:register({
    name = "reset",
    description = "Reset game (optional seed)",
    execute = function(args)
        local seed = tonumber(args[1] or (os.time() + love.timer.getTime()))
        G.world.generator.data = WorldDataComponent.new(seed)
        G:load()
        return true, "Reset (" .. seed .. ")"
    end,
})
