-- Standalone Love2D app to display color palette
-- Run with: love libraries/test
-- Change the require path to test different color palettes

local Colors = require "libraries.colors.init"  -- Change to "colors.resurrect" to test other palette

local BLOCK_SIZE = 32
local PADDING = 4
local LABEL_HEIGHT = 16
local MIN_WINDOW_WIDTH = 400
local MIN_WINDOW_HEIGHT = 300
local MAX_LABEL_LENGTH = 10

local colorList = {}

function love.load()
    love.window.setTitle("Color Palette Viewer")

    -- Collect all colors from the Colors table
    for name, value in pairs(Colors) do
        if type(value) == "table" then
            -- Check if it's a flat color {r, g, b} or grouped {dark = {}, normal = {}, light = {}}
            if type(value[1]) == "number" then
                -- Flat color: {r, g, b}
                table.insert(colorList, {name = name, color = value})
            elseif value.dark or value.normal or value.light then
                -- Grouped colors: {dark = {}, normal = {}, light = {}}
                if value.dark then
                    table.insert(colorList, {name = name .. ".dark", color = value.dark})
                end
                if value.normal then
                    table.insert(colorList, {name = name .. ".normal", color = value.normal})
                end
                if value.light then
                    table.insert(colorList, {name = name .. ".light", color = value.light})
                end
            end
        end
    end

    -- Sort by name for consistent display
    table.sort(colorList, function(a, b) return a.name < b.name end)

    -- Calculate window size
    local cols = math.ceil(math.sqrt(#colorList))
    local rows = math.ceil(#colorList / cols)
    local width = cols * (BLOCK_SIZE + PADDING) + PADDING
    local height = rows * (BLOCK_SIZE + LABEL_HEIGHT + PADDING) + PADDING

    love.window.setMode(math.max(MIN_WINDOW_WIDTH, width), math.max(MIN_WINDOW_HEIGHT, height), {resizable = true})
end

function love.draw()
    love.graphics.clear(0.2, 0.2, 0.2)

    local cols = math.floor((love.graphics.getWidth() - PADDING) / (BLOCK_SIZE + PADDING))
    if cols < 1 then cols = 1 end

    for i, entry in ipairs(colorList) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)

        local x = PADDING + col * (BLOCK_SIZE + PADDING)
        local y = PADDING + row * (BLOCK_SIZE + LABEL_HEIGHT + PADDING)

        -- Draw color block
        local r, g, b = entry.color[1], entry.color[2], entry.color[3]
        love.graphics.setColor(r, g, b)
        love.graphics.rectangle("fill", x, y, BLOCK_SIZE, BLOCK_SIZE)

        -- Draw border
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.rectangle("line", x, y, BLOCK_SIZE, BLOCK_SIZE)

        -- Draw label
        love.graphics.setColor(1, 1, 1)
        local label = entry.name
        if #label > MAX_LABEL_LENGTH then
            label = label:sub(1, MAX_LABEL_LENGTH - 1) .. "…"
        end
        love.graphics.print(label, x, y + BLOCK_SIZE + 2)
    end

    -- Draw info
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Colors: " .. #colorList, 10, love.graphics.getHeight() - 20)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
