-- Main entry point for Lasagna

local game = require("game")
local log = require("lib.log")

-- Global game instance
local G = {}

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
    G.game = game.new(seed, debug)
    game.load(G.game)
    
    log.info("Lasagna loaded")
    log.info("Controls:")
    log.info("  WASD/Arrows - Move")
    log.info("  Space/W/Up - Jump")
    log.info("  Q/E - Switch layers")
    log.info("  1-9 - Select hotbar slot")
    log.info("  Left Click - Mine block")
    log.info("  Right Click - Place block")
    log.info("  +/- - Adjust omnitool tier (dev)")
    log.info("  Delete - Reload world")
    log.info("  Escape - Quit")
end

function love.update(dt)
    if G.game then
        game.update(G.game, dt)
    end
end

function love.draw()
    if G.game then
        game.draw(G.game)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif G.game then
        game.keypressed(G.game, key)
    end
end

function love.mousepressed(x, y, button)
    if G.game then
        game.mousepressed(G.game, x, y, button)
    end
end

function love.resize(width, height)
    if G.game then
        game.resize(G.game, width, height)
    end
end
