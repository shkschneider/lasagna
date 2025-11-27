-- Standalone Love2D app to display color palette
-- Run with: love tests/colors
-- Change the require path to test different color palettes

local Colors = require "libraries.colors.init"  -- Change to "libraries.colors.resurrect" or "libraries.colors.jehkoba"

local TONE_SIZE = 32
local PADDING = 8
local LABEL_HEIGHT = 20
local MIN_WINDOW_WIDTH = 600
local MIN_WINDOW_HEIGHT = 400

local colorGroups = {}

function love.load()
    love.window.setTitle("Color Palette Viewer")

    -- Collect all colors from the Colors table
    for name, value in pairs(Colors) do
        if type(value) == "table" then
            -- Check if it's a flat color {r, g, b} or grouped {dark = {}, normal = {}, light = {}}
            if type(value[1]) == "number" then
                -- Flat color: {r, g, b} - wrap in a single-tone group
                table.insert(colorGroups, {name = name, tones = {value}})
            elseif value.dark or value.normal or value.light then
                -- Grouped colors: {dark = {}, normal = {}, light = {}}
                local tones = {}
                if value.dark then table.insert(tones, value.dark) end
                if value.normal then table.insert(tones, value.normal) end
                if value.light then table.insert(tones, value.light) end
                table.insert(colorGroups, {name = name, tones = tones})
            end
        end
    end

    -- Sort by name for consistent display
    table.sort(colorGroups, function(a, b) return a.name < b.name end)

    -- Calculate window size based on color groups
    local cols = math.ceil(math.sqrt(#colorGroups))
    local rows = math.ceil(#colorGroups / cols)
    local groupWidth = (TONE_SIZE * 3) + PADDING
    local groupHeight = TONE_SIZE + LABEL_HEIGHT + PADDING
    local width = cols * groupWidth + PADDING
    local height = rows * groupHeight + PADDING

    love.window.setMode(math.max(MIN_WINDOW_WIDTH, width), math.max(MIN_WINDOW_HEIGHT, height), {resizable = true})
end

function love.draw()
    love.graphics.clear(0.2, 0.2, 0.2)

    local groupWidth = (TONE_SIZE * 3) + PADDING
    local groupHeight = TONE_SIZE + LABEL_HEIGHT + PADDING
    local cols = math.floor((love.graphics.getWidth() - PADDING) / groupWidth)
    if cols < 1 then cols = 1 end

    for i, group in ipairs(colorGroups) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)

        local x = PADDING + col * groupWidth
        local y = PADDING + row * groupHeight

        -- Draw color name label
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(group.name, x, y)

        -- Draw tone squares (dark to light, left to right)
        for j, tone in ipairs(group.tones) do
            local toneX = x + (j - 1) * TONE_SIZE
            local toneY = y + LABEL_HEIGHT

            -- Draw tone block
            local r, g, b = tone[1], tone[2], tone[3]
            love.graphics.setColor(r, g, b)
            love.graphics.rectangle("fill", toneX, toneY, TONE_SIZE, TONE_SIZE)

            -- Draw border
            love.graphics.setColor(1, 1, 1, 0.3)
            love.graphics.rectangle("line", toneX, toneY, TONE_SIZE, TONE_SIZE)
        end
    end

    -- Draw info
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Color groups: " .. #colorGroups, 10, love.graphics.getHeight() - 20)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
