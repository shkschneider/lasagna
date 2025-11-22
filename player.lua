-- Player entity and controls

local world = require("world")
local inventory = require("inventory")

local player = {}

-- Small epsilon for floating-point boundary precision
local EPSILON = 0.0001

function player.new(x, y, layer)
    return {
        x = x or 0,
        y = y or 0,
        vx = 0,
        vy = 0,
        layer = layer or 0,
        width = world.BLOCK_SIZE * 1,  -- 1 block wide
        height = world.BLOCK_SIZE * 2, -- 2 blocks tall
        on_ground = true,
        inventory = inventory.new(),
        omnitool_tier = 0, -- Starting tier
        mining_progress = 0,
        mining_target = nil, -- {layer, col, row}
    }
end

function player.update(self, dt, w)
    local MOVE_SPEED = 150
    local JUMP_FORCE = 300
    local GRAVITY = 800

    -- Horizontal movement
    self.vx = 0
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        self.vx = -MOVE_SPEED
    end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        self.vx = MOVE_SPEED
    end

    -- Vertical movement (gravity)
    self.vy = self.vy + GRAVITY * dt

    -- Jump
    if (love.keyboard.isDown("w") or love.keyboard.isDown("space") or love.keyboard.isDown("up")) and self.on_ground then
        self.vy = -JUMP_FORCE
        self.on_ground = false
    end

    -- Apply horizontal velocity with collision
    local new_x = self.x + self.vx * dt
    local hit_wall = false

    -- Check horizontal collision only if moving
    if self.vx ~= 0 then
        local check_col
        if self.vx > 0 then
            -- Moving right, check right edge
            check_col = math.floor((new_x + self.width / 2 - EPSILON) / world.BLOCK_SIZE)
        else
            -- Moving left, check left edge
            check_col = math.floor((new_x - self.width / 2) / world.BLOCK_SIZE)
        end

        -- Check all rows the player occupies
        local top_row = math.floor((self.y - self.height / 2) / world.BLOCK_SIZE)
        local bottom_row = math.floor((self.y + self.height / 2 - EPSILON) / world.BLOCK_SIZE)

        for row = top_row, bottom_row do
            local block_proto = world.get_block_proto(w, self.layer, check_col, row)
            if block_proto and block_proto.solid then
                hit_wall = true
                break
            end
        end
    end

    if not hit_wall then
        self.x = new_x
    end

    -- Apply vertical velocity with collision
    local new_y = self.y + self.vy * dt

    -- Check ground collision (bottom of player)
    self.on_ground = false
    local bottom_y = new_y + self.height / 2
    local left_col = math.floor((self.x - self.width / 2) / world.BLOCK_SIZE)
    local right_col = math.floor((self.x + self.width / 2 - EPSILON) / world.BLOCK_SIZE)
    local bottom_row = math.floor(bottom_y / world.BLOCK_SIZE)

    -- Check all blocks at the bottom of the player
    for col = left_col, right_col do
        local block_proto = world.get_block_proto(w, self.layer, col, bottom_row)
        if block_proto and block_proto.solid and self.vy >= 0 then
            -- Collision with ground
            self.y = bottom_row * world.BLOCK_SIZE - self.height / 2
            self.vy = 0
            self.on_ground = true
            new_y = self.y
            break
        end
    end

    -- Check ceiling collision (top of player)
    local top_y = new_y - self.height / 2
    local top_row = math.floor(top_y / world.BLOCK_SIZE)

    for col = left_col, right_col do
        local block_proto = world.get_block_proto(w, self.layer, col, top_row)
        if block_proto and block_proto.solid and self.vy < 0 then
            -- Collision with ceiling
            self.y = (top_row + 1) * world.BLOCK_SIZE + self.height / 2
            self.vy = 0
            new_y = self.y
            break
        end
    end

    if not self.on_ground then
        self.y = new_y
    end

    -- Prevent falling through bottom
    if self.y > world.HEIGHT * world.BLOCK_SIZE then
        self.y = world.HEIGHT * world.BLOCK_SIZE
        self.vy = 0
        self.on_ground = true
    end
end

-- Check if player collides with solid blocks at the given position
function player.check_collision(self, w, x, y, layer)
    layer = layer or self.layer

    -- Player bounding box
    -- Player is 32 pixels wide (exactly 1 block) and 64 pixels tall (exactly 2 blocks)
    local left = x - self.width / 2
    local right = x + self.width / 2
    local top = y - self.height / 2
    local bottom = y + self.height / 2

    -- Convert to block coordinates
    -- We need to check all blocks that the player's bounding box overlaps
    -- Use epsilon to avoid floating-point boundary issues
    local left_col = math.floor(left / world.BLOCK_SIZE)
    local right_col = math.floor((right - EPSILON) / world.BLOCK_SIZE)
    local top_row = math.floor(top / world.BLOCK_SIZE)
    local bottom_row = math.floor((bottom - EPSILON) / world.BLOCK_SIZE)

    -- Check all blocks within the player's bounding box
    for col = left_col, right_col do
        for row = top_row, bottom_row do
            local block_proto = world.get_block_proto(w, layer, col, row)
            if block_proto and block_proto.solid then
                return true
            end
        end
    end

    return false
end

function player.draw(self, camera_x, camera_y)
    love.graphics.setColor(1, 1, 1, 1) -- White player
    love.graphics.rectangle("fill",
        self.x - camera_x - self.width / 2,
        self.y - camera_y - self.height / 2,
        self.width,
        self.height)
end

return player
