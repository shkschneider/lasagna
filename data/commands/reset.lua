local CommandsRegistry = require "registries.commands"
local WorldData = require "src.data.worlddata"
local GameState = require "src.data.gamestate"

CommandsRegistry:register({
    name = "reset",
    description = "Reset game (optional seed)",
    execute = function(args)
        if not G.debug then return false, nil end
        local seed = tonumber(args[1] or (os.time() + love.timer.getTime()))
        G.world.generator.data = WorldData.new(seed)
        G:load(GameState.LOAD)
        return true, "Reset (" .. seed .. ")"
    end,
})
