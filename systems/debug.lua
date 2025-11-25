local Love = require "core.love"
local Object = require "core.object"
local Registry = require "registries"
local BLOCKS = Registry.blocks()
local ITEMS = Registry.items()

local DebugSystem = Object {
    id = "debug",
    enabled = false,
}

function DebugSystem.load(self, _, debug)
    self.enabled = debug or false
    Love.load(self)
end

function DebugSystem.keypressed(self, key)
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
        G:reload()
        return
    end
    -- Adjust omnitool tier
    if key == "=" or key == "+" then
        G.player:upgrade(1)
    elseif key == "-" or key == "_" then
        G.player:upgrade(-1)
    end

    Love.keypressed(self, key)
end

function DebugSystem.draw(self)
    if not self.enabled then
        return
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("Frames: %d/s", love.timer.getFPS()), 10, 100)
    love.graphics.print(string.format("State: %s", G.state:tostring()), 10, 120)
    love.graphics.print(string.format("Time: %s", G.time:tostring()), 10, 140)
    love.graphics.print(string.format("Stance: %s", G.player.stance:tostring()), 10, 160)
    love.graphics.print(string.format("Health: %s", G.player.health:tostring()), 10, 180)
    love.graphics.print(string.format("Stamina: %s", G.player.stamina:tostring()), 10, 200)
    Love.draw(self)
end

return DebugSystem
