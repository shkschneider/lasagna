-- Game System
-- Manages overall game state, time scale, and coordinates other systems

require "core"
local Object = require "core.object"
local GameState = require "components.gamestate"

LAYER_MIN = -1
LAYER_DEFAULT = 0
LAYER_MAX = 1

BLOCK_SIZE = 16
STACK_SIZE = 64

-- Global
Log = require "lib.log"
G = require "core.game"
G.VERSION = { major = 0, minor = 1, patch = nil, tostring = function(self)
    return string.format("%d.%d.%s", self.major, self.minor, tostring(self.patch or "x"))
end }

function love.load()
    local debug = os.getenv("DEBUG") and (os.getenv("DEBUG") == "true") or (G.VERSION.major < 1)
    local seed = tonumber(os.getenv("SEED") or os.time())
    Log.level = debug and "debug" or "warn"
    Log.info("Lasagna", G.VERSION:tostring())
    G:load(seed, debug)
end

function love.update(dt)
    G:update(dt)
end

function love.draw()
    love.graphics.setDefaultFilter("nearest", "nearest")
    Object.draw(G)
end

function love.keypressed(key)
    if key == "escape" then
        G:switch(GameState.QUIT)
        love.event.quit()
        return
    end
    Object.keyreleased(G, key)
end

function love.keyreleased(key)
    Object.keyreleased(G, key)
end

function love.mousepressed(x, y, button)
    Object.mousepressed(G, x, y, button)
end

function love.mousereleased(x, y, button)
    Object.mousereleased(G, x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    Object.mousemoved(G, x, y, dx, dy)
end

function love.wheelmoved(x, y)
    Object.wheelmoved(G, x, y)
end

function love.textinput(text)
    Object.textinput(G, text)
end

function love.resize(width, height)
    Object.resize(G, width, height)
end

function love.focus(focused)
    Object.focus(G, focused)
end

function love.quit()
    Object.quit(G)
end
