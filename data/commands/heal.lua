local CommandsRegistry = require "src.game.registries.commands"

CommandsRegistry:register({
    name = "heal",
    description = "Max health and max stamina",
    execute = function(args)
        if not G.debug then return false, nil end
        G.player.health.current = 100
        G.player.stamina.current = 100
        return true, "Healed"
    end,
})
