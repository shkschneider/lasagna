-- Main entry point for Lasagna
-- Wiring layer: passes LÖVE callbacks to Game

-- Global
G = require("game")

local log = require("lib.log")

function love.load()
    -- Parse environment variables
    local debug = os.getenv("DEBUG") == "true"
    local seed = tonumber(os.getenv("SEED"))

    if debug then
        log.level = "debug"
        log.debug("Debug mode enabled")
    end

    if seed then
        log.info("Using seed:", seed)
    end

    -- Initialize Game and all systems
    G.load(G, seed, debug)

    log.info("Lasagna loaded with system architecture")
end

function love.update(dt)
    G.update(G, dt)
end

function love.draw()
    G.draw(G)
end

function love.keypressed(key)
    G.keypressed(G, key)
end

function love.keyreleased(key)
    G.keyreleased(G, key)
end

function love.mousepressed(x, y, button)
    G.mousepressed(G, x, y, button)
end

function love.mousereleased(x, y, button)
    G.mousereleased(G, x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    G.mousemoved(G, x, y, dx, dy)
end

function love.wheelmoved(x, y)
    G.wheelmoved(G, x, y)
end

function love.resize(width, height)
    G.resize(G, width, height)
end

function love.focus(focused)
    G.focus(G, focused)
end

function love.quit()
    G.quit(G)
end



