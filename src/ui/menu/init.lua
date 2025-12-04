local Love = require "core.love"
local Object = require "core.object"
local GameState = require "src.game.state"

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

        -- Create a radial gradient using a mesh
        local num_segments = 32
        local max_dist = math.sqrt((screen_width/2)^2 + (screen_height/2)^2)

        -- Build vertices for a fan mesh with gradient
        local vertices = {}
        -- Center vertex with 0 opacity
        table.insert(vertices, {center_x, center_y, 0, 0, r, g, b, 0})

        -- Outer ring vertices with full opacity
        for i = 0, num_segments do
            local angle = (i / num_segments) * math.pi * 2
            local x = center_x + math.cos(angle) * max_dist * 1.5  -- Extend beyond screen
            local y = center_y + math.sin(angle) * max_dist * 1.5
            table.insert(vertices, {x, y, 0, 0, r, g, b, 0.85})
        end

        -- Create and draw the mesh
        local mesh = love.graphics.newMesh(vertices, "fan", "static")
        love.graphics.draw(mesh)
    else
        -- For MENU and LOAD, draw solid black background
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", 0, 0, screen_width, screen_height)
    end

    -- Calculate vertical centering
    local line_height = 40
    local total_height = (#self.items + 1) * line_height  -- +1 for title
    local start_y = (screen_height - total_height) / 2

    local font = love.graphics.getFont()
    if state == GameState.MENU then
        -- Draw title
        love.graphics.setColor(1, 1, 1, 1)
        local title_width = font:getWidth(self.title)
        love.graphics.print(self.title, (screen_width - title_width) / 2, 0 + line_height)
    end

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

    if state == GameState.MENU then
        -- Draw footer
        love.graphics.setColor(1, 1, 1, 0.5)
        local footer = "Make with LÖVE by ShkSchneider[.me]"
        local footer_width = font:getWidth(footer)
        love.graphics.print(footer, (screen_width / 2 - footer_width / 2), (screen_height - line_height))
    end

    Love.draw(self)
end

-- Handle keyboard input for menu
function Menu.keypressed(self, key)
    local state = G.state.current

    if state == GameState.LOAD then return end

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
