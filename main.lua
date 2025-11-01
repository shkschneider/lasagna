-- Main application
-- Player produces intents; World.update(dt) applies physics/collision to registered entities.
-- World.draw handles full-scene composition; World.draw_layer draws a single canvas layer.
-- This file now only interfaces with LÖVE APIs and delegates to Game object.

local GameClass = require("game")
local log = require("lib.log")
Game = GameClass()

function love.load()
    love.window.setMode(1280, 720, { resizable = true, minwidth = 640, minheight = 480 })
    love.window.setTitle(Game.NAME)
    Game.screen_width = love.graphics.getWidth()
    Game.screen_height = love.graphics.getHeight()
    Game.seed = os.time()
    Game:regenerate_world()
    log.info("Game loaded")
end

function love.resize(w, h)
    Game.screen_width = w
    Game.screen_height = h
    if Game.ui_canvas and Game.ui_canvas.release then pcall(function() Game.ui_canvas:release() end) end
    Game.ui_canvas = love.graphics.newCanvas(Game.screen_width, Game.screen_height)
    Game.ui_canvas:setFilter("nearest", "nearest")
    clamp_camera()
end

function love.keypressed(key)
    if key == "backspace" then
        Game.debug = not Game.debug
        if Game.debug then
            log.level = "debug"
        else
            log.level = "info"
        end
        log.info("Debug mode: " .. tostring(Game.debug))
        return
    end
    if key == "q" then
        local old_z = Game.player().z
        Game.player().z = math.max(-1, Game.player().z - 1)
        local top = Game.world:get_surface(Game.player().z, math.floor(Game.player().px)) or (Game.WORLD_HEIGHT - 1)
        Game.player().py = top - Game.player().height
        Game.player().vy = 0
        if Game.player().z ~= old_z then
            log.info(string.format("Switched layer: %d -> %d", old_z, Game.player().z))
        end
    elseif key == "e" then
        local old_z = Game.player().z
        Game.player().z = math.min(1, Game.player().z + 1)
        local top = Game.world:get_surface(Game.player().z, math.floor(Game.player().px)) or (Game.WORLD_HEIGHT - 1)
        Game.player().py = top - Game.player().height
        Game.player().vy = 0
        if Game.player().z ~= old_z then
            log.info(string.format("Switched layer: %d -> %d", old_z, Game.player().z))
        end
    elseif key == "escape" then
        love.event.quit()
        return
    end
    
    Game:keypressed(key)
end

function love.wheelmoved(x, y)
    Game:wheelmoved(x, y)
end

function love.mousepressed(x, y, button, istouch, presses)
    Game:mousepressed(x, y, button, istouch, presses)
end

function love.update(dt)
    Game:update(dt)
end

function love.draw()
    Game:draw()
end