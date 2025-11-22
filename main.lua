-- Main entry point for Lasagna

local game = require("game")
local log = require("lib.log")

-- Global game instance
G = {}

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

    -- Initialize game
    G = game.new(seed, debug)
    game.load(G)

    log.info("Lasagna loaded")
end

function love.update(dt)
    game.update(G, dt)
end

function love.draw()
    game.draw(G)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
        return
    end
    game.keypressed(G, key)
end

function love.mousepressed(x, y, button)
    game.mousepressed(G, x, y, button)
end

function love.resize(width, height)
    game.resize(G, width, height)
end
