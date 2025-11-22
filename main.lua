-- Main entry point for Lasagna
-- Wiring layer: passes LÖVE callbacks to Game

-- Global
G = require("game")

local log = require("lib.log")

function love.load()
    log.debug("...")

    -- Parse environment variables
    local debug = os.getenv("DEBUG") == "true"
    local seed = tonumber(os.getenv("SEED") or math.floor(love.math.random() * 1e10))

    if debug then
        log.level = "debug"
        log.debug("Debug mode enabled")
    end

    -- Initialize Game and all systems
    G:load(seed, debug)

    log.info("Lasagna v0.1")
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



