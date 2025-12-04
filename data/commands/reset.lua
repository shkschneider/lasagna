local CommandsRegistry = require "src.registries.commands"
local WorldSeed = require "src.world.seed"
local GameState = require "src.game.state"

CommandsRegistry:register({
    name = "reset",
    description = "Reset game (optional seed)",
    execute = function(args)
        if not G.debug then return false, nil end
        local seed = tonumber(args[1]) or math.round(os.time() + (love.timer.getTime() * 9 ^ 9))
        G.world.generator.data = WorldSeed.new(seed)
        G:load(GameState.LOAD)
        return true, "Reset (" .. seed .. ")"
    end,
})
