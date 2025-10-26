-- Simple Player module (pure logic + drawing helper)
-- Responsibilities:
--  - hold player state (px, py, vx, vy, z, width, height, on_ground)
--  - update physics (gravity, horizontal movement, ground collision)
--  - support step-up movement (small steps)
--  - snapping to surface when changing layers or after regeneration
--  - draw(self, block_size, camera_x) - LOVE-dependent rendering helper
--
-- API:
--   local Player = require("player")
--   local p = Player.new{ px=50, z=0 }
--   p:update(dt, world, { left=bool, right=bool, jump=bool })
--   p:draw(block_size, camera_x)
--
local Player = {}
Player.__index = Player

-- defaults (keys are UPPERCASE)
local DEFAULTS = {
    WIDTH = 1,
    HEIGHT = 2,
    MOVE_SPEED = 5,   -- blocks per second
    JUMP_SPEED = -10, -- initial upward velocity (blocks per second)
    GRAVITY = 20,     -- blocks per second^2
    STEP_HEIGHT = 1,  -- maximum vertical step-up in blocks
}

-- Player drawing color (not a world block)
local PLAYER_COLOR = { 1.0, 1.0, 1.0, 1.0 }

-- compatibility for unpack across Lua versions
local unpack = table.unpack or unpack or function(t)
    return t[1], t[2], t[3], t[4]
end

-- safe floor helper
local function ifloor(v) return math.floor(v) end

-- Create a new player. opts table may include px, py, z, width, height, move_speed, jump_speed, gravity, step_height
function Player.new(opts)
    opts = opts or {}
    local p = setmetatable({}, Player)
    p.px = opts.px or 50
    p.py = opts.py or 0
    p.z  = opts.z  or 0
    p.width  = opts.width  or DEFAULTS.WIDTH
    p.height = opts.height or DEFAULTS.HEIGHT
    p.vx = opts.vx or 0
    p.vy = opts.vy or 0
    p.on_ground = false

    p.move_speed = opts.move_speed or DEFAULTS.MOVE_SPEED
    p.jump_speed = opts.jump_speed or DEFAULTS.JUMP_SPEED
    p.gravity = opts.gravity or DEFAULTS.GRAVITY
    p.step_height = opts.step_height or DEFAULTS.STEP_HEIGHT

    return p
end

-- Snap the player's vertical position to the surface of the current layer at current px
-- world must provide get_surface(z, x) which returns top row number (or nil)
function Player:snap_to_surface(world)
    if not world then return end
    local col = ifloor(self.px)
    local top = world:get_surface(self.z, col) or (world.height and world.height - 1) or 0
    self.py = top - self.height
    self.vy = 0
    self.on_ground = true
end

-- Change player layer and optionally snap to its surface
function Player:set_layer(new_z, world, snap)
    self.z = new_z
    if snap and world then
        self:snap_to_surface(world)
    end
end

-- Get player's center x (useful for collision lookups)
function Player:center_x()
    return self.px + self.width / 2
end

-- Update physics and movement.
-- dt: delta time
-- world: World instance that responds to get_surface(z, x) and has width/height properties
-- input: table { left=bool, right=bool, jump=bool_pressed } - jump should be true only on press
function Player:update(dt, world, input)
    input = input or {}
    -- horizontal target velocity
    local target_vx = 0
    if input.right then target_vx = self.move_speed
    elseif input.left then target_vx = -self.move_speed
    end

    -- move horizontally: compute tentative new position with simple step-up allowed
    local new_px = self.px + target_vx * dt

    -- step-up handling: compare ground at current center vs new center
    local center_x = self.px + self.width / 2
    local new_center_x = new_px + self.width / 2

    local current_col = ifloor(center_x)
    local target_col  = ifloor(new_center_x)

    local current_ground = world and (world:get_surface(self.z, current_col) or (world.height and world.height - 1)) or (math.huge)
    local target_ground  = world and (world:get_surface(self.z, target_col) or (world.height and world.height - 1)) or (math.huge)

    -- allow movement if target ground is at most step_height higher than current ground (or if we're moving upward)
    if (target_ground <= current_ground + self.step_height) or (self.vy < 0) then
        self.px = new_px
        self.vx = target_vx
    else
        -- blocked horizontally by higher terrain, velocity zero horizontally
        self.vx = 0
    end

    -- clamp horizontal inside world if world exposes width
    if world then
        local w = world.width or (world.width and world:width()) or nil
        if w then
            self.px = math.max(1, math.min(w - self.width, self.px))
        end
    end

    -- jumping (only start jump when on ground and jump input true)
    if input.jump and self.on_ground then
        self.vy = self.jump_speed
        self.on_ground = false
    end

    -- gravity
    self.vy = self.vy + self.gravity * dt

    -- vertical integration
    self.py = self.py + self.vy * dt

    -- ground collision: find ground under player's center column
    if world then
        local col = ifloor(self.px + self.width / 2)
        local ground_y = world:get_surface(self.z, col) or (world.height and world.height - 1) or (math.huge)

        if self.vy > 0 and self.py + self.height > ground_y then
            -- landed
            self.py = ground_y - self.height
            self.vy = 0
            self.on_ground = true
        else
            self.on_ground = false
        end

        -- clamp vertical inside world bounds if available
        if world.height then
            self.py = math.min(self.py, world.height - self.height)
        end
    end
end

-- draw the player (uses LOVE). Accepts block_size (pixels) and camera_x (pixels)
-- drawing coordinates map block coordinates to pixels: (px-1)*block_size, (py-1)*block_size
function Player:draw(block_size, camera_x)
    -- require love.graphics to exist in environment calling draw
    love.graphics.push()
    love.graphics.origin()
    love.graphics.translate(- (camera_x or 0), 0)
    love.graphics.setColor(unpack(PLAYER_COLOR))
    love.graphics.rectangle("fill",
            (self.px - 1) * (block_size or 16),
            (self.py - 1) * (block_size or 16),
            (block_size or 16) * self.width,
            (block_size or 16) * self.height)
    love.graphics.pop()
end

-- Optional small helper: returns which block-row the player's feet are over
function Player:foot_row()
    return ifloor(self.py + self.height)
end

-- Returns a simple bbox (x,y,w,h) in block coordinates
function Player:get_bbox()
    return self.px, self.py, self.width, self.height
end

return Player