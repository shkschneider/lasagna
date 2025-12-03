local Love = require "core.love"
local Object = require "core.object"
local Registry = require "src.game.registries"
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
        G.debug = require("src.game.debug").get()
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
    local _, screen_height = love.graphics.getDimensions()
    local line_height = 20
    local start_y = screen_height - (11 * line_height)  -- 11 lines of debug info from bottom

    love.graphics.setColor(1, 1, 1, 1)

    -- Layer indicator
    local pos = G.player.position
    love.graphics.print(string.format("Layer: %d", pos.z), 10, start_y)

    -- Omnitool tier
    local omnitool = G.player.omnitool
    love.graphics.print(string.format("OmniTool: %s", omnitool:tostring()), 10, start_y + line_height)

    -- Player position
    local block_x, block_y = G.world:world_to_block(pos.x, pos.y)
    love.graphics.print(string.format("Position: %d, %d", block_x, block_y), 10, start_y + line_height * 2)

    -- Mouse position
    local mouse_x, mouse_y = love.mouse.getPosition()
    local camera_x, camera_y = G.camera:get_offset()
    local world_x = mouse_x + camera_x
    local world_y = mouse_y + camera_y
    local mouse_col, mouse_row = G.world:world_to_block(world_x, world_y)
    love.graphics.print(string.format("Mouse: %d,%d", mouse_col, mouse_row), 10, start_y + line_height * 3)

    love.graphics.print(string.format("Frames: %d/s", love.timer.getFPS()), 10, start_y + line_height * 4)
    love.graphics.print(string.format("State: %s", G.state:tostring()), 10, start_y + line_height * 5)
    love.graphics.print(string.format("Time: %s", G.time:tostring()), 10, start_y + line_height * 6)
    love.graphics.print(string.format("Stance: %s", G.player.stance:tostring()), 10, start_y + line_height * 7)
    love.graphics.print(string.format("Canvases: %d", table.getn(G.renderer.canvases)), 10, start_y + line_height * 8)
    love.graphics.print(string.format("Entities: %d", 1 + #G.entities.entities), 10, start_y + line_height * 9)
    Love.draw(self)
end

return Debug
