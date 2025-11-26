local Love = require "core.love"
local Object = require "core.object"
local GameStateComponent = require "components.gamestate"

local MenuSystem = Object {
    id = "menu",
    priority = 150,  -- High priority, draws on top of everything
    title = nil,
    items = nil,
}

function MenuSystem.load(self)
    local state = G.state.current
    if state == GameStateComponent.MENU then
        self.title = G.NAME .. " " .. G.VERSION:tostring()
        self.items = require("systems.menu.main")()
    elseif state == GameStateComponent.PAUSE then
        self.title = "Paused"
        self.items = require("systems.menu.pause")()
    elseif state == GameStateComponent.LOAD then
        self.title = "Loading..."
        self.items = require("systems.menu.loading")()
    end
    Love.load(self)
end

-- Draw the menu
function MenuSystem.draw(self)
    local state = G.state.current

    -- Only draw in MENU, PAUSE, or LOAD states
    if state ~= GameStateComponent.MENU and state ~= GameStateComponent.PAUSE and state ~= GameStateComponent.LOAD then
        return
    end

    local screen_width, screen_height = love.graphics.getDimensions()

    -- For PAUSE, draw semi-transparent overlay over the game
    if state == GameStateComponent.PAUSE then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, screen_width, screen_height)
    else
        -- For MENU and LOAD, draw solid black background
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", 0, 0, screen_width, screen_height)
    end

    -- Calculate vertical centering
    local line_height = 40
    local total_height = (#self.items + 1) * line_height  -- +1 for title
    local start_y = (screen_height - total_height) / 2

    -- Draw title
    love.graphics.setColor(1, 1, 1, 1)
    local font = love.graphics.getFont()
    local title_width = font:getWidth(self.title)
    love.graphics.print(self.title, (screen_width - title_width) / 2, start_y)

    -- Draw loading bar for LOAD state
    if state == GameStateComponent.LOAD and G.loader then
        local progress = G.loader:get_progress()
        local bar_width = 200
        local bar_height = 10
        local bar_x = (screen_width - bar_width) / 2
        local bar_y = start_y + line_height + 20

        -- Draw bar background (dark gray)
        love.graphics.setColor(0.3, 0.3, 0.3, 1)
        love.graphics.rectangle("fill", bar_x, bar_y, bar_width, bar_height)

        -- Draw progress fill (white)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", bar_x, bar_y, bar_width * progress, bar_height)

        -- Draw percentage text
        local percent_text = string.format("%d%%", math.floor(progress * 100))
        local percent_width = font:getWidth(percent_text)
        love.graphics.print(percent_text, (screen_width - percent_width) / 2, bar_y + bar_height + 10)
    end

    -- Draw menu items
    for i, item in ipairs(self.items) do
        local y = start_y + i * line_height
        local text = item.label

        if item.enabled then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
        end

        local text_width = font:getWidth(text)
        love.graphics.print(text, (screen_width - text_width) / 2, y)
    end

    Love.draw(self)
end

-- Handle keyboard input for menu
function MenuSystem.keypressed(self, key)
    local state = G.state.current

    -- Only handle input in MENU or PAUSE states (not LOAD)
    if state ~= GameStateComponent.MENU and state ~= GameStateComponent.PAUSE then
        return
    end

    -- Find matching item
    for _, item in ipairs(self.items) do
        if item.key == key and item.enabled and item.action then
            item.action()
            return
        end
    end

    Love.keypressed(self, key)
end

return MenuSystem
