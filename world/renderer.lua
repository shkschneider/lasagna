-- World Renderer
-- Handles all drawing logic for the world, separated from world logic
local Object = require("lib.object")

local Renderer = Object {}

function Renderer:new()
    self.canvases = {}
end

-- Calculate visible columns based on camera position and screen width
function Renderer:get_visible_columns(camera_x, screen_w, block_size)
    local left_col = math.floor(camera_x / block_size)
    local right_col = math.ceil((camera_x + screen_w) / block_size) + 1
    return left_col, right_col
end

-- Calculate alpha for depth effect based on player's layer
function Renderer:calculate_depth_alpha(layer_z, player_z)
    if not player_z or type(player_z) ~= "number" then
        return 1
    end
    
    if layer_z < player_z then
        local depth = player_z - layer_z
        local alpha = 1 - 0.25 * depth
        return math.max(0, alpha)
    end
    
    return 1
end

-- Draw a single block at the specified position
function Renderer:draw_block(proto, px, py, block_size, alpha)
    if not proto then return end
    
    if type(proto.draw) == "function" then
        love.graphics.setColor(1, 1, 1, alpha)
        proto:draw(px, py, block_size)
    elseif proto.color and love and love.graphics then
        local c = proto.color
        love.graphics.setColor(c[1], c[2], c[3], (c[4] or 1) * alpha)
        love.graphics.rectangle("fill", px, py, block_size, block_size)
    end
end

-- Draw all blocks in a visible column
function Renderer:draw_column(world, z, col, block_size, alpha)
    local tiles_z = world.tiles and world.tiles[z]
    if not tiles_z then return end
    
    local column = tiles_z[col]
    if not column then return end
    
    for row = 1, Game.WORLD_HEIGHT do
        local proto = column[row]
        if proto ~= nil then
            local px = (col - 1) * block_size
            local py = (row - 1) * block_size
            self:draw_block(proto, px, py, block_size, alpha)
        end
    end
end

-- Draw a single layer with proper transforms and alpha
function Renderer:draw_layer(world, z, camera_x, left_col, right_col, block_size, alpha)
    local tiles_z = world.tiles[z]
    if not tiles_z then return end
    
    love.graphics.push()
    love.graphics.origin()
    love.graphics.translate(-camera_x, 0)
    
    -- Draw visible columns
    for col = left_col, right_col do
        -- Generate terrain if not yet generated (safety check)
        if not tiles_z[col] then
            world:generate_column(z, col)
        end
        
        self:draw_column(world, z, col, block_size, alpha)
    end
    
    love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1)
end

-- Main draw function - draws all layers and entities
function Renderer:draw(world, camera_x, player, block_size, screen_w, screen_h, debug)
    player = player or (Game and Game.player and Game:player())
    block_size = block_size or (Game and Game.BLOCK_SIZE) or 16
    screen_w = screen_w or (Game and Game.screen_width) or (love.graphics.getWidth and love.graphics.getWidth())
    screen_h = screen_h or (Game and Game.screen_height) or (love.graphics.getHeight and love.graphics.getHeight())
    debug = (debug ~= nil) and debug or (Game and Game.debug)
    
    -- Calculate visible columns
    local left_col, right_col = self:get_visible_columns(camera_x, screen_w, block_size)
    
    local player_z = player and player.z or 0
    
    -- Draw each layer up to and including player's layer
    for z = -1, player_z do
        local alpha = self:calculate_depth_alpha(z, player_z)
        self:draw_layer(world, z, camera_x, left_col, right_col, block_size, alpha)
        
        -- Draw player on their layer
        if player and z == player_z then
            if player.draw then
                player:draw(block_size, camera_x)
            end
        end
    end
    
    -- Draw UI elements (inventory and ghost cursor)
    love.graphics.origin()
    if player and player.drawInventory then
        player:drawInventory(screen_w, screen_h)
    end
    if player and player.drawGhost then
        player:drawGhost(world, camera_x, block_size)
    end
end

return Renderer
