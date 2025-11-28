local Love = require "core.love"
local Object = require "core.object"
local Registry = require "registries"
local BLOCKS = Registry.blocks()
local ITEMS = Registry.items()

local Debug = Object {
    id = "debug",
}

function Debug.get()
    if not G.debug and ((os.getenv("DEBUG") and (os.getenv("DEBUG") == "true")) or (G.VERSION.major < 1)) then
        return Debug
    else
        return nil
    end
end

function Debug.load(self)
    Love.load(self)
end

function Debug.keypressed(self, key)
    if G.chat.in_input_mode then
        return
    end
    if key == "backspace" then
        G.debug = require("src.debug").get()
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

function Debug.draw(self)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("Frames: %d/s", love.timer.getFPS()), 10, 100)
    love.graphics.print(string.format("State: %s", G.state:tostring()), 10, 120)
    love.graphics.print(string.format("Time: %s", G.time:tostring()), 10, 140)
    love.graphics.print(string.format("Stance: %s", G.player.stance:tostring()), 10, 160)
    love.graphics.print(string.format("Health: %s", G.player.health:tostring()), 10, 180)
    love.graphics.print(string.format("Stamina: %s", G.player.stamina:tostring()), 10, 200)
    love.graphics.print(string.format("Canvases: %d", #G.renderer.canvases), 10, 240) -- FIXME always 0
    love.graphics.print(string.format("Entities: %d", 1 + #G.entities.entities), 10, 260)
    Love.draw(self)
end

return Debug
