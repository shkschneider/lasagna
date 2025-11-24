local CommandsRegistry = require "registries.commands"

CommandsRegistry:register({
    name = "heal",
    description = "Max health and max stamina",
    execute = function(args)
        if G.player.health then
            G.player.health.current = 100
        end
        if G.player.stamina then
            G.player.stamina.current = 100
        end
        return true, "Healed"
    end,
})
