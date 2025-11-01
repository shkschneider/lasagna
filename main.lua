local Game = require("game")
local log = require("lib.log")

-- GLOBALS
C = require("constants")
G = Game()

function love.load()
    love.window.setMode(C.RESOLUTIONS.HD.width, C.RESOLUTIONS.HD.height,
        { resizable = true, minwidth = C.RESOLUTIONS.SD.width, minheight = C.RESOLUTIONS.SD.height })
    love.window.setTitle(C.NAME)
    G:load(tonumber(os.getenv("SEED")) or os.time())
end

function love.resize(width, height)
    G:resize(width, height)
    if G.canvas then G.canvas:release() end
    G.canvas = love.graphics.newCanvas(G.width, G.height)
    G.canvas:setFilter("nearest", "nearest")
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "delete" then
        G:load(G.world.seed)
    else
        G:keypressed(key)
    end
end

function love.wheelmoved(x, y)
    G:wheelmoved(x, y)
end

function love.mousepressed(x, y, button, istouch, presses)
    G:mousepressed(x, y, button, istouch, presses)
end

function love.update(dt)
    G:update(dt)
end

function love.draw()
    G:draw()
end
