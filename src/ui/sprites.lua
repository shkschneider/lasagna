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
    
    -- Cached quads for each sprite animation [sprite_name][frame_index] = quad
    _quad_cache = {},
}

-- Load all player sprites
function Sprites.load(self)
    Log.debug("Loading player sprites...")
    
    local base_path = "assets/player/"
    
    -- Helper function to safely load a sprite
    local function safe_load(filename)
        local success, result = pcall(love.graphics.newImage, base_path .. filename)
        if success then
            result:setFilter("nearest", "nearest")
            return result
        else
            Log.warning("Failed to load sprite:", filename, "-", result)
            return nil
        end
    end
    
    -- Load each sprite sheet
    self.player.attack_4 = safe_load("attack_4.png")
    self.player.attack_6 = safe_load("attack_6.png")
    self.player.climb_4 = safe_load("climb_4.png")
    self.player.death_8 = safe_load("death_8.png")
    self.player.hurt_4 = safe_load("hurt_4.png")
    self.player.jump_8 = safe_load("jump_8.png")
    self.player.idle_4 = safe_load("idle_4.png")
    self.player.run_6 = safe_load("run_6.png")
    self.player.walk_6 = safe_load("walk_6.png")
    self.player.default = safe_load("player.png")
    
    Log.debug("Player sprites loaded successfully")
end

-- Get frame count for a sprite animation
local function get_frame_count(sprite_name)
    -- Extract frame count from sprite name (e.g., "attack_4" -> 4)
    local count = tonumber(sprite_name:match("_(%d+)$"))
    return count or 1
end

-- Get or create a quad for a specific sprite frame
-- @param sprite: The sprite image object
-- @param sprite_name: Name of the sprite (for caching)
-- @param frame: Frame index
-- @param frame_width: Width of a single frame
-- @param frame_height: Height of a single frame
-- @param sprite_width: Total width of sprite sheet
-- @param sprite_height: Total height of sprite sheet
-- @return quad object
local function get_or_create_quad(cache, sprite_name, frame, frame_width, frame_height, sprite_width, sprite_height)
    -- Initialize cache for this sprite if needed
    if not cache[sprite_name] then
        cache[sprite_name] = {}
    end
    
    -- Return cached quad if it exists
    if cache[sprite_name][frame] then
        return cache[sprite_name][frame]
    end
    
    -- Create and cache new quad
    local quad = love.graphics.newQuad(
        frame * frame_width, 0,
        frame_width, frame_height,
        sprite_width, sprite_height
    )
    cache[sprite_name][frame] = quad
    return quad
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
    local actual_sprite_name = sprite_name
    if not sprite then
        -- Fallback to default sprite
        sprite = self.player.default
        actual_sprite_name = "default"
        if not sprite then
            -- No sprite available, draw nothing
            return
        end
    end
    
    local sprite_width = sprite:getWidth()
    local sprite_height = sprite:getHeight()
    
    -- Calculate frame dimensions
    local frame_count = get_frame_count(actual_sprite_name)
    local frame_width = sprite_width / frame_count
    local frame_height = sprite_height
    
    -- Clamp frame to valid range
    frame = math.floor(frame) % frame_count
    
    -- Get or create cached quad for this frame
    local quad = get_or_create_quad(
        self._quad_cache,
        actual_sprite_name,
        frame,
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
    local actual_sprite_name = sprite_name
    if not sprite then
        sprite = self.player.default
        actual_sprite_name = "default"
        if not sprite then
            return 16, 32 -- Default fallback size
        end
    end
    
    local frame_count = get_frame_count(actual_sprite_name)
    return sprite:getWidth() / frame_count, sprite:getHeight()
end

return Sprites
