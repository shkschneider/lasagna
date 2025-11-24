local Object = require "core.object"
local Registry = require "registries"

local BLOCKS = Registry.blocks()
local ITEMS = Registry.items()

local Debug = Object.new {
    id = "debug",
    enabled = false,
}

function Debug.load(self, _, debug)
    self.enabled = debug or false
    if self.enabled then
        -- Add weapon items to slots 2 and 3 (slot 1 is for omnitool)
        G.player:add_item_to_inventory(ITEMS.GUN, 1)
        G.player:add_item_to_inventory(ITEMS.ROCKET_LAUNCHER, 1)
    end
end

function Debug.keypressed(self, key)
    if G.chat.in_input_mode then
        return
    end
    -- Debug
    if key == "backspace" then
        self.enabled = not self.enabled
    end
    if not self.enabled then
        return
    end
    -- Reset
    if key == "delete" then -- FIXME
        G:load(G.world.worlddata.seed, G.debug.enabled)
        return
    end
    -- Adjust omnitool tier
    if key == "=" or key == "+" then
        G.player:upgrade(1)
    elseif key == "-" or key == "_" then
        G.player:upgrade(-1)
    end
end

function Debug.draw(self)
    if not self.enabled then
        return
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("Frames: %d/s", love.timer.getFPS()), 10, 100)
    love.graphics.print(string.format("GameState: %s", G.gamestate:tostring()), 10, 120)
    love.graphics.print(string.format("TimeScale: %s", G.timescale:tostring()), 10, 140)
    love.graphics.print(string.format("Stance: %s", G.player.stance:tostring()), 10, 160)
    love.graphics.print(string.format("Health: %s", G.player.health:tostring()), 10, 180)
    love.graphics.print(string.format("Stamina: %s", G.player.stamina:tostring()), 10, 200)
end

return Debug
