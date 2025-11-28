local Love = require "core.love"
local Object = require "core.object"
local TimeComponent = require "components.time"
local GameStateComponent = require "components.gamestate"

-- Helper function to check if input should be ignored based on game state
local function should_ignore_input(state)
    return state == GameStateComponent.MENU or state == GameStateComponent.PAUSE or state == GameStateComponent.LOAD
end

local Game = Object {
    id = "game",
    priority = 0,
    state = nil,
    time = TimeComponent.new(1),
    world = require("systems.world"),
    camera = require("systems.ui.camera"),
    player = require("systems.entities.player"),
    mining = require("systems.mining"),
    building = require("systems.building"),
    weapon = require("systems.weapon"),
    entities = require("systems.entities"),
    ui = require("systems.ui"),
    chat = require("systems.chat"),
    lore = require("systems.lore"),
    menu = require("systems.menu"),
    loader = require("systems.ui.loader"),
    renderer = require("systems.ui.renderer"),
}

function Game.load(self, state)
    self.state = GameStateComponent.new(state or GameStateComponent.BOOT)
    Log.debug(self.state:tostring())
    if state then
        self.state = GameStateComponent.new(state)
        self.menu:load()
    else
        self.state = GameStateComponent.new(GameStateComponent.BOOT)
        self.renderer:load()
        self.state = GameStateComponent.new(GameStateComponent.MENU)
        self.menu:load()
    end
end

function Game.update(self, dt)
    local state = self.state.current
    if state == GameStateComponent.BOOT then
        return -- wait
    elseif state == GameStateComponent.LOAD then
        -- Start loader on first frame of LOAD state
        if not self.loader:is_active() then
            self.loader:start()
        end
        -- Update loader and transition to PLAY when ready
        if self.loader:update(dt) then
            self.loader:reset()
            self:load(GameStateComponent.PLAY)
        end
        return
    elseif state == GameStateComponent.MENU or state == GameStateComponent.PAUSE then
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
        if state == GameStateComponent.PLAY then
            self:load(GameStateComponent.PAUSE)
            return
        elseif state == GameStateComponent.PAUSE then
            self:load(GameStateComponent.PLAY)
            return
        elseif state == GameStateComponent.MENU then
            self:load(GameStateComponent.QUIT)
            love.event.quit()
            return
        end
    end
    if state == GameStateComponent.MENU or state == GameStateComponent.PAUSE then
        self.menu:keypressed(key)
        return
    elseif state == GameStateComponent.LOAD then
        return  -- No input during loading
    else
        Love.keypressed(self, key)
    end
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
    Love.resize(self, width, height)
end

function Game.focus(self, focused)
    Love.focus(self, focused)
end

function Game.quit(self)
    Love.quit(self)
end

return Game
