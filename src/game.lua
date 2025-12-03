local Love = require "core.love"
local Object = require "core.object"
local GameState = require "src.data.gamestate"

local Game = Object {
    id = "game",
    priority = 0,
    -- Systems
    state = require("src.systems.state"),
    time = require("src.systems.time"),
    fade = require("src.systems.fade"),
    loader_system = require("src.systems.loader"),
    -- Game modules
    world = require("src.world"),
    camera = require("src.camera"),
    player = require("src.entities.player"),
    mining = require("src.world.mining"),
    building = require("src.world.building"),
    entities = require("src.entities"),
    weapon = require("src.items.weapon"),
    ui = require("src.ui"),
    chat = require("src.chat"),
    lore = require("src.lore"),
    menu = require("src.ui.menu"),
    loader = require("src.ui.loader"),
    renderer = require("src.renderer"),
}

function Game.load(self, state)
    if state then 
        -- Loading a specific state (called from elsewhere)
        self.state:transition_to(state)
        Log.debug(self.state.current:tostring())
    else
        -- Initial load (boot -> menu)
        self.state:transition_to(GameState.MENU)
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
    -- Apply time scaling
    local scaled_dt = self.time:get_scaled_dt(dt)
    
    -- Update all systems and modules
    Love.update(self, scaled_dt)
end

function Game.draw(self)
    self.renderer:draw() -- NOT Love.draw
end

function Game.keypressed(self, key)
    local state = self.state.current.current
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

function Game.keyreleased(self, key)
    if self.state:should_ignore_input() then return end
    Love.keyreleased(self, key)
end

function Game.mousepressed(self, x, y, button)
    if self.state:should_ignore_input() then return end
    Love.mousepressed(self, x, y, button)
end

function Game.mousereleased(self, x, y, button)
    if self.state:should_ignore_input() then return end
    Love.mousereleased(self, x, y, button)
end

function Game.mousemoved(self, x, y, dx, dy)
    if self.state:should_ignore_input() then return end
    Love.mousemoved(self, x, y, dx, dy)
end

function Game.wheelmoved(self, x, y)
    if self.state:should_ignore_input() then return end
    Love.wheelmoved(self, x, y)
end

function Game.textinput(self, text)
    if self.state:should_ignore_input() then return end
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
