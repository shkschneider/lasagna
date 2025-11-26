require "core"

-- Global: game

G = require("core.game")
G.NAME = "Lasagna"
G.VERSION = { major = 0, minor = 1, patch = nil, tostring = function(self)
    return string.format("%d.%d.%s", self.major, self.minor, tostring(self.patch or "x"))
end }

-- Global: log

Log = require "libraries.rxi.log"

-- Global: constants

LAYER_MIN = -1
LAYER_DEFAULT = 0
LAYER_MAX = 1
BLOCK_SIZE = 16
STACK_SIZE = 64

-- love2d

local Love = require "core.love"
local GameStateComponent = require "components.gamestate"

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    local debug = os.getenv("DEBUG") and (os.getenv("DEBUG") == "true") or (G.VERSION.major < 1)
    Log.level = debug and "debug" or "warn"
    Log.info(G.NAME, G.VERSION:tostring())
    if debug then
        G.debug = require("systems.debug")
    end
    -- Do NOT load()
    G:switch(GameStateComponent.MENU)
end

function love.update(dt)
    local state = G.state.current
    if state == GameStateComponent.MENU or state == GameStateComponent.PAUSE then
        return
    end
    if G.player and G.player:is_dead() then return end
    dt = dt * G.time.scale
    Love.update(G, dt)
end

function love.draw()
    local state = G.state.current
    if state == GameStateComponent.MENU or state == GameStateComponent.PAUSE then
        G.menu:draw() -- FIXME draws alone not on top of world (if pause)
    else
        Love.draw(G)
    end
end

function love.keypressed(key)
    local state = G.state.current
    if key == "escape" then
        if state == GameStateComponent.PLAY then
            G:switch(GameStateComponent.PAUSE)
            return
        elseif state == GameStateComponent.PAUSE then
            G:switch(GameStateComponent.PLAY)
            return
        elseif state == GameStateComponent.MENU then
            G:switch(GameStateComponent.QUIT)
            love.event.quit()
            return
        end
    end
    if state == GameStateComponent.MENU or state == GameStateComponent.PAUSE then
        G.menu:keypressed(key)
        return
    else
        Love.keypressed(G, key)
    end
end

function love.keyreleased(key)
    local state = G.state.current
    if state == GameStateComponent.MENU or state == GameStateComponent.PAUSE then
        return
    end
    Love.keyreleased(G, key)
end

function love.mousepressed(x, y, button)
    local state = G.state.current
    if state == GameStateComponent.MENU or state == GameStateComponent.PAUSE then
        return
    end
    Love.mousepressed(G, x, y, button)
end

function love.mousereleased(x, y, button)
    local state = G.state.current
    if state == GameStateComponent.MENU or state == GameStateComponent.PAUSE then
        return
    end
    Love.mousereleased(G, x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    local state = G.state.current
    if state == GameStateComponent.MENU or state == GameStateComponent.PAUSE then
        return
    end
    Love.mousemoved(G, x, y, dx, dy)
end

function love.wheelmoved(x, y)
    local state = G.state.current
    if state == GameStateComponent.MENU or state == GameStateComponent.PAUSE then
        return
    end
    Love.wheelmoved(G, x, y)
end

function love.textinput(text)
    local state = G.state.current
    if state == GameStateComponent.MENU or state == GameStateComponent.PAUSE then
        return
    end
    Love.textinput(G, text)
end

function love.resize(width, height)
    Love.resize(G, width, height)
end

function love.focus(focused)
    Love.focus(G, focused)
end

function love.quit()
    Love.quit(G)
end
