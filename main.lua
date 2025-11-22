-- Global
G = require "game"
G.VERSION = { major = 0, minor = 1, patch = 3, tostring = function(self)
    return string.format("%d.%d.%d", self.major, self.minor, self.patch)
end }

local log = require "lib.log"

function love.load()
    local debug = os.getenv("DEBUG") == "true"
    local seed = tonumber(os.getenv("SEED"))
    log.level = debug and "debug" or "warn"
    log.debug("...")
    G:load(seed, debug)
    log.info("Lasagna", G.VERSION:tostring())
end

function love.update(dt)
    G:update(dt)
end

function love.draw()
    G:draw()
end

function love.keypressed(key)
    G:keypressed(key)
end

function love.keyreleased(key)
    G:keyreleased(key)
end

function love.mousepressed(x, y, button)
    G:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    G:mousereleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    G:mousemoved(x, y, dx, dy)
end

function love.wheelmoved(x, y)
    G:wheelmoved(x, y)
end

function love.resize(width, height)
    G:resize(width, height)
end

function love.focus(focused)
    G:focus(focused)
end

function love.quit()
    G:quit()
end
