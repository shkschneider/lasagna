local Systems = require "systems"
local Registry = require "registries"

local BLOCKS = Registry.blocks()
local ITEMS = Registry.items()

local Debug = {
    id = "debug",
    enabled = false,
}

function Debug.load(self, seed, debug)
    self.enabled = debug or false
    if self.enabled then
        local player = Systems.get("player")
        if player then
            -- Clear existing inventory
            for i = 1, player.components.inventory.hotbar_size do
                player.components.inventory.slots[i] = nil
            end

            -- Add weapon items
            player:add_item_to_inventory(ITEMS.GUN, 1)
            player:add_item_to_inventory(ITEMS.ROCKET_LAUNCHER, 1)
        end
    end
end

function Debug.keypressed(self, key)
    if key == "backspace" then
        local chat = Systems.get("chat")
        if not chat.in_input_mode then
            self.enabled = not self.enabled
        end
    end
end

function Debug.draw(self)
    if self.enabled then
        local player = Systems.get("player")
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(string.format("Frames: %d/s", love.timer.getFPS()), 10, 100)
        love.graphics.print(string.format("GameState: %s", G.components.gamestate:tostring()), 10, 120)
        love.graphics.print(string.format("TimeScale: %s", G.components.timescale:tostring()), 10, 140)
        love.graphics.print(string.format("Stance: %s", player.components.stance:tostring()), 10, 160)
    end
end

return Debug
