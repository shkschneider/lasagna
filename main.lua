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
local async = require "libraries.luax.async"

-- Loading state tracking
local loading_task = nil
local loading_start_time = nil
local LOADING_MIN_DURATION = 1  -- Minimum loading screen duration in seconds

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    local debug = os.getenv("DEBUG") and (os.getenv("DEBUG") == "true") or (G.VERSION.major < 1)
    Log.level = debug and "debug" or "warn"
    Log.info(G.NAME, G.VERSION:tostring())
    if debug then
        G.debug = require("systems.debug")
    end
    -- Do NOT load()
    G.state = GameStateComponent.new(GameStateComponent.MENU)
    G.menu:load()
end

function love.update(dt)
    local state = G.state.current

    -- Handle LOADING state - perform world generation and player spawn
    if state == GameStateComponent.LOADING then
        -- Start loading task if not already started
        if not loading_task then
            loading_start_time = love.timer.getTime()
            loading_task = async.spawn(function(task)
                -- Perform the actual game loading (world generation, player spawn)
                G:load()
                -- Apply save data if we were loading a saved game
                if G.pending_save_data then
                    G.save:apply_save_data(G.pending_save_data)
                    G.pending_save_data = nil
                end
                -- Wait for minimum loading duration
                local elapsed = love.timer.getTime() - loading_start_time
                local remaining = LOADING_MIN_DURATION - elapsed
                if remaining > 0 then
                    task:sleep(remaining)
                end
            end)
        end

        -- Update async scheduler
        async.update(dt)

        -- Check if loading is complete
        if loading_task and loading_task.result then
            loading_task = nil
            loading_start_time = nil
            -- State is now PLAY (set by G:load)
        end
        return
    end

    if state == GameStateComponent.MENU or state == GameStateComponent.PAUSE then
        return
    end
    if G.player and G.player:is_dead() then return end
    dt = dt * G.time.scale
    Love.update(G, dt)
end

function love.draw()
    local state = G.state.current
    if state == GameStateComponent.MENU or state == GameStateComponent.PAUSE or state == GameStateComponent.LOADING then
        G.menu:draw()
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
    elseif state == GameStateComponent.LOADING then
        return  -- No input during loading
    else
        Love.keypressed(G, key)
    end
end

function love.keyreleased(key)
    local state = G.state.current
    if state == GameStateComponent.MENU or state == GameStateComponent.PAUSE or state == GameStateComponent.LOADING then
        return
    end
    Love.keyreleased(G, key)
end

function love.mousepressed(x, y, button)
    local state = G.state.current
    if state == GameStateComponent.MENU or state == GameStateComponent.PAUSE or state == GameStateComponent.LOADING then
        return
    end
    Love.mousepressed(G, x, y, button)
end

function love.mousereleased(x, y, button)
    local state = G.state.current
    if state == GameStateComponent.MENU or state == GameStateComponent.PAUSE or state == GameStateComponent.LOADING then
        return
    end
    Love.mousereleased(G, x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    local state = G.state.current
    if state == GameStateComponent.MENU or state == GameStateComponent.PAUSE or state == GameStateComponent.LOADING then
        return
    end
    Love.mousemoved(G, x, y, dx, dy)
end

function love.wheelmoved(x, y)
    local state = G.state.current
    if state == GameStateComponent.MENU or state == GameStateComponent.PAUSE or state == GameStateComponent.LOADING then
        return
    end
    Love.wheelmoved(G, x, y)
end

function love.textinput(text)
    local state = G.state.current
    if state == GameStateComponent.MENU or state == GameStateComponent.PAUSE or state == GameStateComponent.LOADING then
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
