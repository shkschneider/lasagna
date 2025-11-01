-- Main application
-- Player produces intents; World.update(dt) applies physics/collision to registered entities.
-- World.draw handles full-scene composition; World.draw_layer draws a single canvas layer.
-- This file now only interfaces with LÖVE APIs and delegates to Game object.

local GameClass = require("game")
local log = require("lib.log")
Game = GameClass()

function love.load()
    local resolutions = {
        sd = { p = 480,  width = 854,  height = 480 },
        hd = { p = 720,  width = 1280, height = 720 },
        fhd = { p = 1080, width = 1920, height = 1080 },
    }
    love.window.setMode(resolutions.hd.width, resolutions.hd.height,
        { resizable = true, minwidth = resolutions.sd.width, minheight = resolutions.sd.height })
    love.window.setTitle(Game.NAME)
    Game:load(os.getenv("SEED") or os.time())
end

function love.resize(width, height)
    Game:resize(width, height)
    if Game.ui_canvas and Game.ui_canvas.release then pcall(function() Game.ui_canvas:release() end) end
    Game.ui_canvas = love.graphics.newCanvas(Game.screen_width, Game.screen_height)
    Game.ui_canvas:setFilter("nearest", "nearest")
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "delete" then
        Game:load(Game.world.seed)
    else
        Game:keypressed(key)
    end
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