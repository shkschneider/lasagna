-- Main application
-- Player produces intents; World.update(dt) applies physics/collision to registered entities.
-- World.draw handles full-scene composition; World.draw_layer draws a single canvas layer.
-- This file now only interfaces with LÖVE APIs and delegates to Game object.

local GameClass = require("game")

-- Create global Game instance for compatibility with existing code
Game = GameClass()

function love.load()
    love.window.setMode(1280, 720, { resizable = true, minwidth = 640, minheight = 480 })
    love.window.setTitle(Game.NAME)

    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()
    
    Game:load(screen_width, screen_height)
end

function love.resize(w, h)
    Game:resize(w, h)
end

function love.keypressed(key)
    if key == "escape" then
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