-- Render System
-- Handles all rendering operations

local Systems = require "systems"
local Registry = require "registries"

local RenderSystem = {
    id = "render",
    priority = 100,
    canvases = {},
    screen_width = 1280,
    screen_height = 720,
}

function RenderSystem.load(self)
    self:create_canvases()
end

function RenderSystem.create_canvases(self)
    self.screen_width, self.screen_height = love.graphics.getDimensions()

    -- Create canvases for each layer
    self.canvases[-1] = love.graphics.newCanvas(self.screen_width, self.screen_height)
    self.canvases[0] = love.graphics.newCanvas(self.screen_width, self.screen_height)
    self.canvases[1] = love.graphics.newCanvas(self.screen_width, self.screen_height)
end

function RenderSystem.draw(self)
    -- Get systems from G
    local world_system = Systems.get("world")
    local player_system = Systems.get("player")
    local camera_system = Systems.get("camera")

    if not world_system or not player_system or not camera_system then
        return
    end

    local camera_x, camera_y = camera_system:get_offset()
    local player_x, player_y, player_layer = player_system:get_position()

    -- Draw world to layer canvases
    self:draw_world(world_system, player_layer, camera_x, camera_y)

    -- Composite layers to screen
    self:composite_layers(player_layer)

    -- Draw player
    player_system:draw(camera_x, camera_y)

    -- Draw UI
    self:draw_ui(player_system, world_system, camera_x, camera_y)
end

function RenderSystem.draw_world(self, world_system, player_layer, camera_x, camera_y)
    local start_col = math.floor(camera_x / world_system.BLOCK_SIZE) - 1
    local end_col = math.ceil((camera_x + self.screen_width) / world_system.BLOCK_SIZE) + 1
    local start_row = math.floor(camera_y / world_system.BLOCK_SIZE) - 1
    local end_row = math.ceil((camera_y + self.screen_height) / world_system.BLOCK_SIZE) + 1

    -- Clamp to world bounds
    start_col = math.max(0, start_col)
    end_col = math.min(world_system.WIDTH - 1, end_col)
    start_row = math.max(0, start_row)
    end_row = math.min(world_system.HEIGHT - 1, end_row)

    -- Draw each layer to its canvas
    for layer = -1, 1 do
        local canvas = self.canvases[layer]
        if canvas then
            love.graphics.setCanvas(canvas)
            love.graphics.clear(0, 0, 0, 0)

            -- Draw blocks
            for col = start_col, end_col do
                for row = start_row, end_row do
                    local block_id = world_system:get_block(layer, col, row)
                    local proto = Registry.Blocks:get(block_id)

                    if proto and proto.solid then
                        love.graphics.setColor(proto.color)
                        local x = col * world_system.BLOCK_SIZE - camera_x
                        local y = row * world_system.BLOCK_SIZE - camera_y
                        love.graphics.rectangle("fill", x, y, world_system.BLOCK_SIZE, world_system.BLOCK_SIZE)
                    end
                end
            end

            love.graphics.setCanvas()
        end
    end
end

function RenderSystem.composite_layers(self, player_layer)
    -- Clear screen
    love.graphics.clear(0.4, 0.6, 0.9, 1) -- Sky blue background

    -- Draw back layer (dimmed)
    if self.canvases[-1] then
        if player_layer == -1 then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 1) -- Dimmed
        end
        love.graphics.draw(self.canvases[-1], 0, 0)
    end

    -- Draw main layer
    if self.canvases[0] then
        if player_layer == 0 then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(0.7, 0.7, 0.7, 1) -- Slightly dimmed
        end
        love.graphics.draw(self.canvases[0], 0, 0)
    end

    -- Draw front layer (semi-transparent)
    if self.canvases[1] then
        if player_layer == 1 then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(1, 1, 1, 0.6) -- Semi-transparent
        end
        love.graphics.draw(self.canvases[1], 0, 0)
    end
end

function RenderSystem.draw_ui(self, player_system, world_system, camera_x, camera_y)
    local pos = player_system.components.position
    local inv = player_system.components.inventory
    local omnitool = player_system.components.omnitool

    -- Layer indicator
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("Layer: %d", pos.z), 10, 10)

    -- Omnitool tier
    love.graphics.print(string.format("Omnitool Tier: %d", omnitool.tier), 10, 30)

    -- Player position
    local block_x, block_y = world_system:world_to_block(pos.x, pos.y)
    love.graphics.print(string.format("Position: %d, %d", block_x, block_y), 10, 50)

    -- Mouse position and block under cursor
    local mouse_x, mouse_y = love.mouse.getPosition()
    local world_x = mouse_x + camera_x
    local world_y = mouse_y + camera_y
    local mouse_col, mouse_row = world_system:world_to_block(world_x, world_y)
    local block_proto = world_system:get_block_proto(pos.z, mouse_col, mouse_row)
    local block_name = block_proto and block_proto.name or "Air"
    love.graphics.print(string.format("Mouse: %d, %d (%s)", mouse_col, mouse_row, block_name), 10, 70)

    -- Draw hotbar
    local hotbar_y = self.screen_height - 80
    local slot_size = 60
    local hotbar_x = (self.screen_width - (inv.hotbar_size * slot_size)) / 2

    for i = 1, inv.hotbar_size do
        local x = hotbar_x + (i - 1) * slot_size

        -- Slot background
        if i == inv.selected_slot then
            love.graphics.setColor(1, 1, 0, 0.5) -- Yellow for selected
        else
            love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
        end
        love.graphics.rectangle("fill", x, hotbar_y, slot_size - 4, slot_size - 4)

        -- Slot border
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.rectangle("line", x, hotbar_y, slot_size - 4, slot_size - 4)

        -- Item in slot
        local slot = inv.slots[i]
        if slot then
            local proto = Registry.Blocks:get(slot.block_id)
            if proto then
                -- Draw item as colored square
                love.graphics.setColor(proto.color)
                love.graphics.rectangle("fill", x + 8, hotbar_y + 8, slot_size - 20, slot_size - 20)

                -- Draw count
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.print(tostring(slot.count), x + 4, hotbar_y + slot_size - 20)
            end
        end
    end

    -- Selected item name above hotbar
    local selected_slot = inv.slots[inv.selected_slot]
    if selected_slot then
        local proto = Registry.Blocks:get(selected_slot.block_id)
        if proto then
            love.graphics.setColor(1, 1, 1, 1)
            local text = proto.name
            local text_width = love.graphics.getFont():getWidth(text)
            love.graphics.print(text, (self.screen_width - text_width) / 2, hotbar_y - 25)
        end
    end
end

function RenderSystem.resize(self, width, height)
    self.screen_width = width
    self.screen_height = height
    self:create_canvases()
end

return RenderSystem
