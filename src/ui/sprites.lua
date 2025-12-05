local Object = require "core.object"

-- Sprite system for managing and drawing animated sprite sheets
local Sprites = Object {
    id = "sprites",
    priority = 100, -- Low priority (drawn after other systems)
    
    -- Sprite data storage
    player = {
        -- Sprite sheets indexed by animation name
        attack_4 = nil,      -- Range weapon attack (4 frames)
        attack_6 = nil,      -- Melee weapon attack (6 frames)
        climb_4 = nil,       -- Climbing animation (4 frames)
        death_8 = nil,       -- Death animation (8 frames)
        hurt_4 = nil,        -- Hurt animation (4 frames)
        jump_8 = nil,        -- Jump animation (8 frames)
        idle_4 = nil,        -- Idle animation (4 frames)
        run_6 = nil,         -- Sprint/run animation (6 frames)
        walk_6 = nil,        -- Walk animation (6 frames)
        default = nil,       -- Default sprite (player.png)
    },
}

-- Load all player sprites
function Sprites.load(self)
    Log.debug("Loading player sprites...")
    
    local base_path = "assets/player/"
    
    -- Load each sprite sheet
    self.player.attack_4 = love.graphics.newImage(base_path .. "attack_4.png")
    self.player.attack_6 = love.graphics.newImage(base_path .. "attack_6.png")
    self.player.climb_4 = love.graphics.newImage(base_path .. "climb_4.png")
    self.player.death_8 = love.graphics.newImage(base_path .. "death_8.png")
    self.player.hurt_4 = love.graphics.newImage(base_path .. "hurt_4.png")
    self.player.jump_8 = love.graphics.newImage(base_path .. "jump_8.png")
    self.player.idle_4 = love.graphics.newImage(base_path .. "idle_4.png")
    self.player.run_6 = love.graphics.newImage(base_path .. "run_6.png")
    self.player.walk_6 = love.graphics.newImage(base_path .. "walk_6.png")
    self.player.default = love.graphics.newImage(base_path .. "player.png")
    
    -- Set filter mode for pixel-perfect rendering
    for _, sprite in pairs(self.player) do
        if sprite then
            sprite:setFilter("nearest", "nearest")
        end
    end
    
    Log.debug("Player sprites loaded successfully")
end

-- Get frame count for a sprite animation
local function get_frame_count(sprite_name)
    -- Extract frame count from sprite name (e.g., "attack_4" -> 4)
    local count = tonumber(sprite_name:match("_(%d+)$"))
    return count or 1
end

-- Draw a player sprite with animation support
-- @param sprite_name: Name of the sprite animation (e.g., "walk_6", "idle_4", "default")
-- @param x, y: Screen position to draw at
-- @param frame: Current frame index (0-based, for animations)
-- @param facing_right: Boolean, true if facing right, false if facing left
-- @param scale: Optional scale multiplier (default 1.0)
function Sprites.draw_player(self, sprite_name, x, y, frame, facing_right, scale)
    scale = scale or 1.0
    frame = frame or 0
    facing_right = (facing_right == nil) and true or facing_right
    
    -- Get the sprite image
    local sprite = self.player[sprite_name]
    if not sprite then
        -- Fallback to default sprite
        sprite = self.player.default
        if not sprite then
            -- No sprite available, draw nothing
            return
        end
    end
    
    local sprite_width = sprite:getWidth()
    local sprite_height = sprite:getHeight()
    
    -- Calculate frame dimensions
    local frame_count = get_frame_count(sprite_name)
    local frame_width = sprite_width / frame_count
    local frame_height = sprite_height
    
    -- Clamp frame to valid range
    frame = math.floor(frame) % frame_count
    
    -- Create quad for the current frame
    local quad = love.graphics.newQuad(
        frame * frame_width, 0,
        frame_width, frame_height,
        sprite_width, sprite_height
    )
    
    -- Calculate draw position (center the sprite)
    local draw_x = x
    local draw_y = y
    
    -- Handle horizontal flipping for direction
    local scale_x = facing_right and scale or -scale
    local offset_x = facing_right and 0 or frame_width * scale
    
    -- Draw the sprite
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        sprite,
        quad,
        draw_x + offset_x,
        draw_y,
        0, -- rotation
        scale_x, scale, -- scale x, y
        frame_width / 2, frame_height / 2 -- origin offset (center)
    )
end

-- Get sprite dimensions for a given sprite
-- @param sprite_name: Name of the sprite
-- @return width, height of a single frame
function Sprites.get_frame_size(self, sprite_name)
    local sprite = self.player[sprite_name]
    if not sprite then
        sprite = self.player.default
        if not sprite then
            return 16, 32 -- Default fallback size
        end
    end
    
    local frame_count = get_frame_count(sprite_name)
    return sprite:getWidth() / frame_count, sprite:getHeight()
end

return Sprites
