local Systems = require "systems"
local Registry = require "registries"

local BLOCKS = Registry.blocks()

local Debug = {
    id = "debug",
    enabled = false,
}

function Debug.load(self, seed, debug)
    self.enabled = debug or false
    if self.enabled then
        local player = Systems.get("player")
        if player then
            -- Add starting items
            player:add_to_inventory(BLOCKS.DIRT, 64)
            player:add_to_inventory(BLOCKS.STONE, 32)
            player:add_to_inventory(BLOCKS.WOOD, 16)
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

        -- Display player stance
        if player and player.components and player.components.stance then
            love.graphics.print(string.format("Stance: %s", player.components.stance.current), 10, 160)
        end
    end
end

return Debug
