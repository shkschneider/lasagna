local Love = require "core.love"
local Object = require "core.object"
local TimeScale = require "src.game.timescale"
local GameState = require "src.game.state"

-- Fade effect constants
local FADE_DURATION = 1  -- 1 second fade duration

local Game = Object {
    id = "game",
    priority = 0,
    world = require("src.world"),
    camera = require("src.ui.camera"),
    player = require("src.entities.player"),
    mining = require("src.world.mining"),
    building = require("src.world.building"),
    entities = require("src.entities"),
    ui = require("src.ui"),
    chat = require("src.ui.chat"),
    lore = require("src.game.lore"),
    menu = require("src.ui.menu"),
    loader = require("src.ui.loader"),
    renderer = require("src.ui.renderer"),
    init = function(self)
        self.state = GameState.new(GameState.BOOT)
        self.time = TimeScale.new(1)
        self.fade_alpha = 0  -- 0 = transparent, 1 = black
        self.fade_duration = FADE_DURATION
        self.fade_timer = 0
        self.fade_direction = nil  -- "in" (black to transparent) or "out" (transparent to black)
    end,
}

function Game.load(self, state)
    if state then assert(self.state) end
    self.state = GameState.new(state or GameState.BOOT)
    Log.debug(self.state:tostring())
    -- initial (boot -> menu)
    if not state then
        self.state = GameState.new(GameState.MENU)
        self.debug = require("src.game.debug").get()
        if self.debug then
            Log.level = 0 -- all
            dassert.DEBUG = true
        end
        dassert(self.NAME and self.VERSION)
        Log.info(self.NAME, self.VERSION:tostring())
    end
    self.menu:load()
end

function Game.update(self, dt)
    local state = self.state.current
    if state == GameState.BOOT then
        return -- wait
    elseif state == GameState.LOAD then
        if not self.loader:is_active() then
            self.loader:start()
        end
        if self.loader:update(dt) then
            self.loader:reset()
            self:load(GameState.PLAY)
            -- Start fade-in when entering PLAY state
            self:start_fade_in()
        end
        return
    elseif state == GameState.MENU or state == GameState.PAUSE then
        return
    elseif self.player:is_dead() and state ~= GameState.DEAD then
        self:load(GameState.DEAD)
    end
    if state == GameState.DEAD then return end

    -- Update fade effect
    if self.fade_direction then
        self.fade_timer = self.fade_timer + dt
        local progress = math.min(self.fade_timer / self.fade_duration, 1.0)

        if self.fade_direction == "in" then
            -- Fade in: black (1.0) to transparent (0.0)
            self.fade_alpha = 1.0 - progress
        elseif self.fade_direction == "out" then
            -- Fade out: transparent (0.0) to black (1.0)
            self.fade_alpha = progress
        end

        -- End fade when complete
        if progress >= 1.0 then
            self.fade_direction = nil
            self.fade_timer = 0
        end
    end

    dt = dt * self.time.scale
    Love.update(self, dt)
end

function Game.start_fade_in(self)
    self.fade_direction = "in"
    self.fade_timer = 0
    self.fade_alpha = 1.0
end

function Game.start_fade_out(self)
    self.fade_direction = "out"
    self.fade_timer = 0
    self.fade_alpha = 0.0
end

function Game.draw(self)
    self.renderer:draw() -- NOT Love.draw

    -- Draw fade overlay
    if self.fade_alpha > 0 then
        love.graphics.setColor(0, 0, 0, self.fade_alpha)
        local width, height = love.graphics.getDimensions()
        love.graphics.rectangle("fill", 0, 0, width, height)
        love.graphics.setColor(1, 1, 1, 1)  -- Reset color
    end
end

function Game.keypressed(self, key)
    local state = self.state.current
    if key == "escape" then
        if state == GameState.PLAY then
            self:load(GameState.PAUSE)
            return
        elseif state == GameState.PAUSE then
            self:load(GameState.PLAY)
            return
        elseif state == GameState.MENU then
            self:load(GameState.QUIT)
            love.event.quit()
            return
        elseif state == GameState.DEAD then
            self:load(GameState.MENU)
            return
        end
        -- DEAD state: escape does nothing
    end
    if state == GameState.MENU or state == GameState.PAUSE or state == GameState.DEAD then
        self.menu:keypressed(key)
        return
    elseif state == GameState.LOAD then
        return  -- No input during loading
    else
        Love.keypressed(self, key)
    end
end

local function should_ignore_input(state)
    return state == GameState.MENU or state == GameState.PAUSE or state == GameState.LOAD or state == GameState.DEAD
end

function Game.keyreleased(self, key)
    if should_ignore_input(self.state.current) then return end
    Love.keyreleased(self, key)
end

function Game.mousepressed(self, x, y, button)
    if should_ignore_input(self.state.current) then return end
    Love.mousepressed(self, x, y, button)
end

function Game.mousereleased(self, x, y, button)
    if should_ignore_input(self.state.current) then return end
    Love.mousereleased(self, x, y, button)
end

function Game.mousemoved(self, x, y, dx, dy)
    if should_ignore_input(self.state.current) then return end
    Love.mousemoved(self, x, y, dx, dy)
end

function Game.wheelmoved(self, x, y)
    if should_ignore_input(self.state.current) then return end
    Love.wheelmoved(self, x, y)
end

function Game.textinput(self, text)
    if should_ignore_input(self.state.current) then return end
    Love.textinput(self, text)
end

function Game.resize(self, width, height) -- FIXME does not scale up
    Log.verbose("Game.resize", width, height)
    Love.resize(self, width, height)
end

function Game.focus(self, focused)
    if focused then Log.verbose("Game.focused") end
    Love.focus(self, focused)
end

function Game.quit(self)
    Log.verbose("Game.quit")
    Love.quit(self)
end

return Game
