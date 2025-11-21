-- Rendering system with layer canvases

local world = require("world")
local blocks = require("blocks")
local inventory = require("inventory")

local render = {}

function render.new()
    return {
        canvases = {},
        screen_width = 1280,
        screen_height = 720,
    }
end

function render.create_canvases(r)
    r.screen_width, r.screen_height = love.graphics.getDimensions()
    
    -- Create canvases for each layer
    r.canvases[-1] = love.graphics.newCanvas(r.screen_width, r.screen_height)
    r.canvases[0] = love.graphics.newCanvas(r.screen_width, r.screen_height)
    r.canvases[1] = love.graphics.newCanvas(r.screen_width, r.screen_height)
end

function render.draw_world(r, w, player_layer, camera_x, camera_y)
    local start_col = math.floor(camera_x / world.BLOCK_SIZE) - 1
    local end_col = math.ceil((camera_x + r.screen_width) / world.BLOCK_SIZE) + 1
    local start_row = math.floor(camera_y / world.BLOCK_SIZE) - 1
    local end_row = math.ceil((camera_y + r.screen_height) / world.BLOCK_SIZE) + 1
    
    -- Clamp to world bounds
    start_col = math.max(0, start_col)
    end_col = math.min(world.WIDTH - 1, end_col)
    start_row = math.max(0, start_row)
    end_row = math.min(world.HEIGHT - 1, end_row)
    
    -- Draw each layer to its canvas
    for layer = -1, 1 do
        local canvas = r.canvases[layer]
        if canvas then
            love.graphics.setCanvas(canvas)
            love.graphics.clear(0, 0, 0, 0)
            
            -- Draw blocks
            for col = start_col, end_col do
                for row = start_row, end_row do
                    local block_id = world.get_block(w, layer, col, row)
                    local proto = blocks.get_proto(block_id)
                    
                    if proto and proto.solid then
                        love.graphics.setColor(proto.color)
                        local x = col * world.BLOCK_SIZE - camera_x
                        local y = row * world.BLOCK_SIZE - camera_y
                        love.graphics.rectangle("fill", x, y, world.BLOCK_SIZE, world.BLOCK_SIZE)
                    end
                end
            end
            
            love.graphics.setCanvas()
        end
    end
end

function render.composite_layers(r, player_layer)
    -- Clear screen
    love.graphics.clear(0.4, 0.6, 0.9, 1) -- Sky blue background
    
    -- Draw back layer (dimmed)
    if r.canvases[-1] then
        if player_layer == -1 then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 1) -- Dimmed
        end
        love.graphics.draw(r.canvases[-1], 0, 0)
    end
    
    -- Draw main layer
    if r.canvases[0] then
        if player_layer == 0 then
            love.graphics.setColor(1, 1, 1, 1)
        elseif player_layer == -1 then
            love.graphics.setColor(1, 1, 1, 0.5) -- Semi-transparent (in front)
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 1) -- Dimmed (behind)
        end
        love.graphics.draw(r.canvases[0], 0, 0)
    end
    
    -- Draw front layer
    if r.canvases[1] then
        if player_layer == 1 then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(1, 1, 1, 0.5) -- Semi-transparent
        end
        love.graphics.draw(r.canvases[1], 0, 0)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function render.draw_ui(r, p, w, camera_x, camera_y)
    local inv = p.inventory
    if not inv then return end
    
    -- Draw hotbar
    local hotbar_y = r.screen_height - 60
    local slot_size = 50
    local hotbar_width = inventory.HOTBAR_SIZE * slot_size
    local hotbar_x = (r.screen_width - hotbar_width) / 2
    
    for i = 1, inventory.HOTBAR_SIZE do
        local x = hotbar_x + (i - 1) * slot_size
        
        -- Draw slot background
        if i == inv.selected_slot then
            love.graphics.setColor(1, 1, 0.5, 0.8) -- Highlighted
        else
            love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        end
        love.graphics.rectangle("fill", x, hotbar_y, slot_size - 2, slot_size - 2)
        
        -- Draw item
        local slot = inv.slots[i]
        if slot then
            local proto = blocks.get_proto(slot.block_id)
            if proto then
                love.graphics.setColor(proto.color)
                love.graphics.rectangle("fill", x + 5, hotbar_y + 5, 
                    slot_size - 12, slot_size - 12)
                
                -- Draw count
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.print(tostring(slot.count), x + 5, hotbar_y + slot_size - 20)
            end
        end
        
        -- Draw slot number
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(tostring(i), x + 2, hotbar_y + 2)
    end
    
    -- Draw selected block name above hotbar (centered)
    local selected_slot = inv.slots[inv.selected_slot]
    if selected_slot then
        local proto = blocks.get_proto(selected_slot.block_id)
        if proto then
            local text = proto.name
            local font = love.graphics.getFont()
            local text_width = font:getWidth(text)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(text, (r.screen_width - text_width) / 2, hotbar_y - 25)
        end
    end
    
    -- Draw top-left overlay with player position and mouse info
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 5, 5, 250, 80)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Layer: " .. p.layer, 10, 10)
    love.graphics.print("Omnitool Tier: " .. p.omnitool_tier, 10, 30)
    
    -- Player position in blocks
    local player_col = math.floor(p.x / world.BLOCK_SIZE)
    local player_row = math.floor(p.y / world.BLOCK_SIZE)
    love.graphics.print("Player: " .. player_col .. ", " .. player_row, 10, 50)
    
    -- Mouse position and block name under cursor
    if camera_x and camera_y then
        local mouse_x, mouse_y = love.mouse.getPosition()
        local world_x = mouse_x + camera_x
        local world_y = mouse_y + camera_y
        local mouse_col, mouse_row = world.world_to_block(world_x, world_y)
        
        local block_id = world.get_block(w, p.layer, mouse_col, mouse_row)
        local block_proto = blocks.get_proto(block_id)
        local block_name = block_proto and block_proto.name or "Unknown"
        
        love.graphics.print("Mouse: " .. mouse_col .. ", " .. mouse_row .. " (" .. block_name .. ")", 10, 70)
    end
end

return render
