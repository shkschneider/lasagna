local CommandsRegistry = require "src.registries.commands"

CommandsRegistry:register({
    name = "god",
    description = "Invincible",
    execute = function(args)
        if not G.debug then return false, nil end
        if G.player.health then
            if not G.player.health.invincible then
                G.player.health.invincible = true
                return true, "Invincible"
            else
                G.player.health.invincible = false
                return true, "Mortal"
            end
        end
        return false, nil
    end,
})
