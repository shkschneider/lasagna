assert(love)

local Object = require "core.object"
local Love = require "core.love"

Log = require "libraries.log"
local Game = Object {}

function Game.draw(self)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("It works!", 0, 0)
end

function love.load()
    Game:load()
end

function love.update(dt)
    Game:update(dt)
end

function love.draw()
    Game:draw()
    love.event.quit(0)
end
