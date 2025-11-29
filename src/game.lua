local Love = require "core.love"
local Object = require "core.object"
local TimeScale = require "src.data.timescale"
local GameState = require "src.data.gamestate"

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
    lore = require("src.lore"),
    menu = require("src.ui.menu"),
    loader = require("src.ui.loader"),
    renderer = require("src.ui.renderer"),
    init = function(self)
        self.state = GameState.new(GameState.BOOT)
        self.time = TimeScale.new(1)
    end,
}

function Game.load(self, state)
    if state then assert(self.state) end
    self.state = GameState.new(state or GameState.BOOT)
    Log.debug(self.state:tostring())
    -- initial (boot -> menu)
    if not state then
        self.state = GameState.new(GameState.MENU)
        self.debug = require("src.debug").get()
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
        end
        return
    elseif state == GameState.MENU or state == GameState.PAUSE then
        return
    end
    if self.player and self.player:is_dead() then return end
    dt = dt * self.time.scale
    Love.update(self, dt)
end

function Game.draw(self)
    self.renderer:draw() -- NOT Love.draw
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
        end
    end
    if state == GameState.MENU or state == GameState.PAUSE then
        self.menu:keypressed(key)
        return
    elseif state == GameState.LOAD then
        return  -- No input during loading
    else
        Love.keypressed(self, key)
    end
end

local function should_ignore_input(state)
    return state == GameState.MENU or state == GameState.PAUSE or state == GameState.LOAD
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

function Game.resize(self, width, height)
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
