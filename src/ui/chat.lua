local Love = require "core.love"
local Object = require "core.object"
local Registry = require "src.game.registries"

local Chat = Object {
    id = "chat",
    priority = 120, -- After UI (110)
}

function Chat.load(self)
    self.open = false
    self.input = ""
    self.history = {} -- Chat message history
    self.max_history = 9^2
    self.message_timer = 0 -- Timer for message visibility
    self.message_display_duration = 5 -- Seconds to show messages
    self.in_input_mode = false -- Whether user is typing
    Love.load(self)
end

function Chat.update(self, dt)
    -- Update message visibility timer
    if self.message_timer > 0 then
        self.message_timer = self.message_timer - dt
        if self.message_timer <= 0 then
            self.message_timer = 0
            -- Only close if not in input mode
            if not self.in_input_mode then
                self.open = false
            end
        end
    end
    Love.update(self, dt)
end

function Chat.draw(self)
    if not self.open then
        return
    end

    local screen_width, screen_height = love.graphics.getDimensions()

    -- Chat dimensions: 1/3 width, up to 1/2 height
    local chat_width = screen_width / 3
    local chat_max_height = screen_height / 2
    local chat_padding = 10
    local line_height = 20

    -- Calculate actual height based on history
    local num_lines = math.min(#self.history + 1, math.floor((chat_max_height - chat_padding * 2) / line_height))
    local chat_height = num_lines * line_height + chat_padding * 2
    if not self.in_input_mode then
        chat_height = chat_height - line_height
    end

    -- Position at bottom left
    local chat_x = 10
    local chat_y = screen_height - chat_height - 10

    -- Calculate opacity based on timer (dim in last second)
    local background_opacity = 0.7
    local text_opacity = 1.0
    if not self.in_input_mode and self.message_timer > 0 and self.message_timer < 1 then
        -- Fade out in the last second
        local fade_factor = self.message_timer -- 0 to 1
        background_opacity = 0.7 * fade_factor
        text_opacity = fade_factor
    end

    -- Draw dimmed background
    love.graphics.setColor(0, 0, 0, background_opacity)
    love.graphics.rectangle("fill", chat_x, chat_y, chat_width, chat_height)

    -- Draw chat history
    love.graphics.setColor(1, 1, 1, text_opacity)
    local history_y = chat_y + chat_padding
    local visible_history_count = math.min(#self.history, num_lines - 1)
    local start_index = math.max(1, #self.history - visible_history_count + 1)

    for i = start_index, #self.history do
        local message = self.history[i]
        love.graphics.print(message, chat_x + chat_padding, history_y)
        history_y = history_y + line_height
    end

    -- Draw input line with cursor (only if in input mode)
    if self.in_input_mode then
        love.graphics.setColor(1, 1, 1, 1)
        local input_text = "> " .. self.input .. "_"
        love.graphics.print(input_text, chat_x + chat_padding, history_y)
    end

    Love.draw(self)
end

function Chat.keypressed(self, key)
    -- FIXME pausing while chat open/edit
    -- FIXME open command with /, /reset, then / only opens chat not commands
    -- Check if we should toggle chat
    if key == "return" then
        if not self.in_input_mode then
            self.open = true
            self.in_input_mode = true
            self.message_timer = 0 -- Stop auto-hide timer
            love.keyboard.setTextInput(true)
        else
            -- Submit the input
            if self.input ~= "" then
                self:process_input(self.input)
            end
            self.input = ""
            self.in_input_mode = false
            love.keyboard.setTextInput(false)
            -- Start timer to auto-hide after 10 seconds
            self.message_timer = self.message_display_duration
        end
        return
    elseif key == "/" then
        if not self.in_input_mode then
            local was_open = self.open
            self.open = true
            self.in_input_mode = true
            self.message_timer = 0
            self.input = was_open and "/" or ""
            love.keyboard.setTextInput(true)
        end
    end

    if not self.in_input_mode then
        return
    end

    -- Handle backspace
    if key == "backspace" then
        if #self.input > 0 then
            self.input = self.input:sub(1, -2)
        end
    end

    -- Handle escape to close chat
    if key == "escape" then
        self.open = false
        self.in_input_mode = false
        self.input = ""
        self.message_timer = 0
        love.keyboard.setTextInput(false)
    end

    Love.keypressed(self, key)
end

function Chat.textinput(self, text)
    if self.in_input_mode then
        self.input = self.input .. text
    end
    Love.textinput(self, text)
end

function Chat.process_input(self, input)
    -- Check if it's a command (starts with /)
    if input:sub(1, 1) == "/" then
        local command_parts = {}
        for part in input:gmatch("%S+") do
            table.insert(command_parts, part)
        end

        if #command_parts > 0 then
            local command_name = command_parts[1]:sub(2) -- Remove leading /
            local args = {}
            for i = 2, #command_parts do
                table.insert(args, command_parts[i])
            end

            if G.debug then
                -- Add input to history
                self:add_message("> " .. input)
                -- Execute command
                local success, message = Registry.Commands:execute(command_name, args)
                Log.info("<", command_name, ">", tostring(success), ":", tostring(message))
                if message then
                    self:add_message(message)
                end
            end
        end
    else
        -- Regular chat message (not a command)
        -- For now, just echo it
        self:add_message(input)
    end
end

function Chat.add_message(self, message)
    table.insert(self.history, string.format("%f: %s", love.timer.getTime(), message))

    -- Keep history limited
    while #self.history > self.max_history do
        table.remove(self.history, 1)
    end

    -- Show chat when message arrives (if not already in input mode)
    self.open = true
    if not self.in_input_mode then
        self.message_timer = self.message_display_duration
    end
end

return Chat
