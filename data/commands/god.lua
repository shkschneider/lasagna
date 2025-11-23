local CommandsRegistry = require("registries.commands")
local Systems = require "systems"

-- Register /ping command
CommandsRegistry:register({
    name = "god",
    description = "Invincible",
    execute = function(args)
        local player = Systems.get("player")
        if player.components.health then
            if not player.components.health.invincible then
                player.components.health.invincible = true
                return true, "Invincible"
            else
                player.components.health.invincible = false
                return true, "Mortal"
            end
        end
        return false, nil
    end,
})
