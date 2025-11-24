local Object = require "core.object"
local Systems = require "systems"
local Registry = require "registries"

local BLOCKS = Registry.blocks()
local ITEMS = Registry.items()

local Debug = Object.new {
    id = "debug",
    enabled = false,
}

function Debug.load(self, seed, debug)
    self.enabled = debug or false
    if self.enabled then
        local player = Systems.get("player")
        if player then
            -- Add weapon items to slots 2 and 3 (slot 1 is for omnitool)
            player:add_item_to_inventory(ITEMS.GUN, 1)
            player:add_item_to_inventory(ITEMS.ROCKET_LAUNCHER, 1)
        end
    end
end

function Debug.keypressed(self, key)
    local chat = Systems.get("chat")
    if chat.in_input_mode then
        return
    end
    -- Debug
    if key == "backspace" then
        self.enabled = not self.enabled
    end
    if not self.enabled then
        return
    end
    -- Adjust omnitool tier
    if key == "=" or key == "+" then
        local player = Systems.get("player")
        player:upgrade(1)
    elseif key == "-" or key == "_" then
        local player = Systems.get("player")
        player:upgrade(-1)
    end
end

function Debug.draw(self)
    if not self.enabled then
        return
    end
    local player = Systems.get("player")
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("Frames: %d/s", love.timer.getFPS()), 10, 100)
    love.graphics.print(string.format("GameState: %s", G.gamestate:tostring()), 10, 120)
    love.graphics.print(string.format("TimeScale: %s", G.timescale:tostring()), 10, 140)
    love.graphics.print(string.format("Stance: %s", player.stance:tostring()), 10, 160)
    love.graphics.print(string.format("Health: %s", player.health:tostring()), 10, 180)
    love.graphics.print(string.format("Stamina: %s", player.stamina:tostring()), 10, 200)
end

return Debug
