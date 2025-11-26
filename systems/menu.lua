-- Menu System
-- Handles main menu and pause menu display and input
--
-- Main Menu (GameState.MENU):
--   1 Continue (only if save exists)
--   2 New Game
--   3 Quit
--
-- Pause Menu (GameState.PAUSE):
--   1 Continue
--   2 Save Game
--   3 Load Game (only if save exists)
--   4 Quit

local Love = require "core.love"
local Object = require "core.object"
local GameStateComponent = require "components.gamestate"

local MenuSystem = Object { -- TODO split file in systems|src menu/main + menu/paused
    id = "menu",
    priority = 150,  -- High priority, draws on top of everything
}

-- Menu item structure: {key = "1", label = "Option text", action = function, enabled = true/false}

-- Get main menu items
function MenuSystem.get_main_menu_items(self)
    local items = {}

    -- Continue (only if save exists)
    local save_exists = G.save:exists()
    table.insert(items, {
        key = "c",
        label = "[C] ontinue",
        enabled = save_exists,
        action = function()
            -- Load save data first to get the seed
            local save_data = G.save:load()
            if save_data then
                -- Initialize game with the saved seed TODO FIXME
                G:load()
                -- Apply save data (restores player position, inventory, etc.)
                G.save:apply_save_data(save_data)
                -- State is already PLAY from G:load
            end
        end
    })

    -- New Game
    table.insert(items, {
        key = "n",
        label = "[N] ew Game",
        enabled = true,
        action = function()
            G:load() -- FIXME seed and stuff
        end
    })

    -- Quit
    table.insert(items, {
        key = "q",
        label = "[Q] uit",
        enabled = true,
        action = function()
            G:switch(GameStateComponent.QUIT)
            love.event.quit()
        end
    })

    return items
end

-- Get pause menu items
function MenuSystem.get_pause_menu_items(self)
    local items = {}

    -- Continue
    table.insert(items, {
        key = "c",
        label = "[C] ontinue",
        enabled = true,
        action = function()
            G:switch(GameStateComponent.PLAY)
        end
    })

    -- Save Game
    table.insert(items, {
        key = "s",
        label = "[S] ave Game",
        enabled = true,
        action = function()
            G.save:save()
            G:switch(GameStateComponent.PLAY)
        end
    })

    -- Load Game (only if save exists)
    local save_exists = G.save:exists()
    table.insert(items, {
        key = "l",
        label = "[L] oad Game",
        enabled = save_exists,
        action = function()
            local save_data = G.save:load()
            if save_data then
                -- Reload game with saved seed FIXME
                G:load()
                -- Apply save data
                G.save:apply_save_data(save_data)
                -- State is already PLAY from G:load
            end
        end
    })

    -- Quit
    table.insert(items, {
        key = "q",
        label = "[Q] uit",
        enabled = true,
        action = function()
            -- TODO save
            G:switch(GameStateComponent.MENU)
        end
    })

    return items
end

-- Draw the menu
function MenuSystem.draw(self)
    local state = G.state.current

    -- Only draw in MENU or PAUSE states
    if state ~= GameStateComponent.MENU and state ~= GameStateComponent.PAUSE then
        return
    end

    local screen_width, screen_height = love.graphics.getDimensions()

    -- For PAUSE, draw semi-transparent overlay over the game
    if state == GameStateComponent.PAUSE then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, screen_width, screen_height)
    else
        -- For MENU, draw solid black background
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", 0, 0, screen_width, screen_height)
    end

    -- Get appropriate menu items
    local items
    local title
    if state == GameStateComponent.MENU then
        items = self:get_main_menu_items()
        title = G.NAME .. " " .. G.VERSION:tostring()
    else
        items = self:get_pause_menu_items()
        title = "Paused"
    end

    -- Calculate vertical centering
    local line_height = 40
    local total_height = (#items + 1) * line_height  -- +1 for title
    local start_y = (screen_height - total_height) / 2

    -- Draw title
    love.graphics.setColor(1, 1, 1, 1)
    local font = love.graphics.getFont()
    local title_width = font:getWidth(title)
    love.graphics.print(title, (screen_width - title_width) / 2, start_y)

    -- Draw menu items
    for i, item in ipairs(items) do
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

    -- Only handle input in MENU or PAUSE states
    if state ~= GameStateComponent.MENU and state ~= GameStateComponent.PAUSE then
        return
    end

    -- Get appropriate menu items
    local items
    if state == GameStateComponent.MENU then
        items = self:get_main_menu_items()
    else
        items = self:get_pause_menu_items()
    end

    -- Find matching item
    for _, item in ipairs(items) do
        if item.key == key and item.enabled and item.action then
            item.action()
            return
        end
    end

    Love.keypressed(self, key)
end

return MenuSystem
