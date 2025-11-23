local CommandsRegistry = require("registries.commands")
local Systems = require("systems")

CommandsRegistry:register({
    name = "heal",
    description = "Max health and max stamina",
    execute = function(args)
        local player = System.get("player")
        if player.components.health then
            player.components.health.current = 100
        end
        if player.compoments.stamina then
            player.components.stamina.current = 100
        end
        return true, "Healed"
    end,
})
