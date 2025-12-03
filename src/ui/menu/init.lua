local Love = require "core.love"
local Object = require "core.object"
local GameState = require "src.data.gamestate"

local Menu = Object {
    id = "menu",
    priority = 150,  -- High priority, draws on top of everything
    title = nil,
    items = nil,
}

function Menu.load(self)
    local state = G.state.current
    if state == GameState.MENU then
        self.title = G.NAME .. " " .. G.VERSION:tostring()
        self.items = require("src.ui.menu.main")()
    elseif state == GameState.PAUSE then
        self.title = "Paused"
        self.items = require("src.ui.menu.pause")()
    elseif state == GameState.LOAD then
        self.title = "Loading..."
        self.items = require("src.ui.menu.loading")()
    elseif state == GameState.DEAD then
        self.title = "You Died"
        self.items = require("src.ui.menu.dead")()
    end
    Love.load(self)
end

-- Draw the menu
function Menu.draw(self)
    local state = G.state.current

    -- Only draw in MENU, PAUSE, LOAD, or DEAD states
    if state ~= GameState.MENU and state ~= GameState.PAUSE and state ~= GameState.LOAD and state ~= GameState.DEAD then
        return
    end

    local screen_width, screen_height = love.graphics.getDimensions()
    local center_x, center_y = screen_width / 2, screen_height / 2
    local max_radius = math.sqrt(center_x * center_x + center_y * center_y)

    -- Draw gradient overlay for PAUSE and DEAD states
    if state == GameState.PAUSE or state == GameState.DEAD then
        -- Determine base color: red for DEAD, black for PAUSE
        local r, g, b = 0, 0, 0
        if state == GameState.DEAD then
            r = 1  -- Red for death
        end
        
        -- Draw radial gradient from center (0% opacity) to edges (85% opacity for visibility)
        local segments = 64  -- Number of segments for smooth gradient
        for i = segments, 1, -1 do
            local radius = (i / segments) * max_radius
            local alpha = (i / segments) * 0.85  -- 0% at center to 85% at edges
            love.graphics.setColor(r, g, b, alpha)
            love.graphics.circle("fill", center_x, center_y, radius, segments)
        end
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
    if state == GameState.LOAD and G.loader then
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
function Menu.keypressed(self, key)
    local state = G.state.current

    -- Only handle input in MENU, PAUSE, or DEAD states (not LOAD)
    if state ~= GameState.MENU and state ~= GameState.PAUSE and state ~= GameState.DEAD then
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

return Menu
