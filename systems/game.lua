local Love = require "core.love"
local Object = require "core.object"
local TimeComponent = require "components.time"
local GameStateComponent = require "components.gamestate"
local Shaders = require "libraries.shaders"

local Game = Object {
    id = "game",
    priority = 0,
    state = GameStateComponent.new(GameStateComponent.BOOT),
    time = TimeComponent.new(1),
    canvases = require("systems.ui.canvases"),
    world = require("systems.world"),
    camera = require("systems.ui.camera"),
    player = require("systems.entities.player"),
    mining = require("systems.mining"),
    building = require("systems.building"),
    weapon = require("systems.weapon"),
    entity = require("systems.entities"),
    ui = require("systems.ui"),
    chat = require("systems.chat"),
    lore = require("systems.lore"),
    menu = require("systems.menu"),
    loader = require("systems.ui.loader"),
}

function Game.switch(self, gamestate)
    assert(gamestate)
    self.state = GameStateComponent.new(gamestate)
    Log.debug(string.format("%f", love.timer.getTime()), "Game", string.upper(self.state:tostring()))
    G.menu:load()
end

function Game.load(self)
    self:switch(GameStateComponent.LOAD)
    Love.load(self)
    self:switch(GameStateComponent.PLAY)
end

-- Draw all canvases to screen (called from love.draw)
function Game.draw(self)
    local state = self.state.current
    if state == GameStateComponent.MENU or state == GameStateComponent.LOAD then
        self.menu:draw()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.canvases.menu, 0, 0)
        return
    end

    Love.draw(self)
    love.graphics.clear(0.4, 0.6, 0.9, 1)

    -- 1. Terrain layers
    local player_z = self.player.position.z
    local max_layer = math.min(player_z + 1, LAYER_MAX)
    love.graphics.setBlendMode("alpha", "premultiplied")
    for layer = LAYER_MIN, max_layer do
        -- Apply greyscale shader to back layer (-1)
        if layer == -1 then
            love.graphics.setShader(Shaders.greyscale)
        end
        love.graphics.draw(self.canvases.layers[layer], 0, 0)
        if layer == -1 then
            love.graphics.setShader()
        end
    end
    love.graphics.setBlendMode("alpha")

    -- 2. Player canvas with light shader
    local camera_x, camera_y = self.camera:get_offset()
    local player_screen_x = self.player.position.x - camera_x
    local player_screen_y = self.player.position.y - camera_y
    Shaders.light:send("playerPosition", {player_screen_x, player_screen_y})
    love.graphics.setShader(Shaders.light)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.canvases.player, 0, 0)
    love.graphics.setShader()

    -- 3. Entities canvas
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.canvases.entities, 0, 0)

    -- 4. UI canvas
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.canvases.ui, 0, 0)

    -- 5. Menu canvas (for PAUSE state)
    if state == GameStateComponent.PAUSE then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.canvases.menu, 0, 0)
    end
end

return Game
