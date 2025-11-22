-- Player System
-- Manages player entity and player-specific logic

require "lib"
local log = require "lib.log"

local Systems = require "systems"
local Position = require "components.position"
local Velocity = require "components.velocity"
local Physics = require "components.physics"
local Collider = require "components.collider"
local Visual = require "components.visual"
local Layer = require "components.layer"
local Inventory = require "components.inventory"
local Omnitool = require "components.omnitool"
local Stance = require "components.stance"
local Controllable = require "components.controllable"
local Registry = require "registries"

local BLOCKS = Registry.blocks()

local PlayerSystem = {
    id = "player",
    priority = 20,
    components = {},
    -- Height constants
    STANDING_HEIGHT = nil,  -- Will be set in load
    CROUCHING_HEIGHT = nil, -- Will be set in load
}

function PlayerSystem.load(self, x, y, layer)
    local world = Systems.get("world")

    -- Set height constants
    self.STANDING_HEIGHT = world.BLOCK_SIZE * 2
    self.CROUCHING_HEIGHT = self.STANDING_HEIGHT / 2

    -- Initialize player components
    self.components.position = Position.new(x, y, layer)
    self.components.velocity = Velocity.new(0, 0)
    self.components.physics = Physics.new(true, 800, 0.95)
    self.components.collider = Collider.new(world.BLOCK_SIZE, self.STANDING_HEIGHT)
    self.components.visual = Visual.new({1, 1, 1, 1}, world.BLOCK_SIZE, self.STANDING_HEIGHT)
    self.components.layer = Layer.new(layer)
    self.components.inventory = Inventory.new(9, 64)
    self.components.omnitool = Omnitool.new(0)
    self.components.stance = Stance.new(Stance.STANDING)
    self.components.controllable = Controllable.new(150, 300)

    -- Initialize inventory slots
    for i = 1, self.components.inventory.hotbar_size do
        self.components.inventory.slots[i] = nil
    end

    -- Add starting items
    self:add_to_inventory(BLOCKS.DIRT, 64)
    self:add_to_inventory(BLOCKS.STONE, 32)
    self:add_to_inventory(BLOCKS.WOOD, 16)

    log.info("Player:", self.components.position:tostring())
end

function PlayerSystem.update(self, dt)
    local world = Systems.get("world")

    local pos = self.components.position
    local vel = self.components.velocity
    local phys = self.components.physics
    local col = self.components.collider
    local stance = self.components.stance
    local ctrl = self.components.controllable

    -- Process input and control through controllable component
    ctrl:update(dt, self.components, self.STANDING_HEIGHT, self.CROUCHING_HEIGHT, world)

    -- Vertical movement (gravity)
    vel.vy = vel.vy + phys.gravity * dt

    -- Apply horizontal velocity with collision
    local new_x = pos.x + vel.vx * dt
    local hit_wall = false

    if vel.vx ~= 0 then
        local check_col
        if vel.vx > 0 then
            check_col = math.floor((new_x + col.width / 2) / world.BLOCK_SIZE)
        else
            check_col = math.floor((new_x - col.width / 2) / world.BLOCK_SIZE)
        end

        local top_row = math.floor((pos.y - col.height / 2) / world.BLOCK_SIZE)
        local bottom_row = math.floor((pos.y + col.height / 2 - EPSILON) / world.BLOCK_SIZE)

        for row = top_row, bottom_row do
            local block_def = world:get_block_def(pos.z, check_col, row)
            if block_def and block_def.solid then
                hit_wall = true
                if vel.vx > 0 then
                    pos.x = check_col * world.BLOCK_SIZE - col.width / 2
                else
                    pos.x = (check_col + 1) * world.BLOCK_SIZE + col.width / 2
                end
                break
            end
        end

        -- Edge detection: prevent falling off edges while crouching
        -- Allow player to move halfway off the edge
        if not hit_wall and stance.current == Stance.CROUCHING and phys.on_ground and vel.vx ~= 0 then
            local ground_check_row = math.floor((pos.y + col.height / 2) / world.BLOCK_SIZE) + 1
            local ground_exists = false

            -- Check if there's ground under the edge we're moving toward
            -- Allow movement until half the player's width would be over the edge
            local edge_check_col
            if vel.vx > 0 then
                -- Moving right: check if right half would be over empty space
                edge_check_col = math.floor((new_x + col.width / 4) / world.BLOCK_SIZE)
            else
                -- Moving left: check if left half would be over empty space
                edge_check_col = math.floor((new_x - col.width / 4) / world.BLOCK_SIZE)
            end

            local block_def = world:get_block_def(pos.z, edge_check_col, ground_check_row)
            if block_def and block_def.solid then
                ground_exists = true
            end

            -- If no ground under the half-block position, stop movement
            if not ground_exists then
                hit_wall = true
            end
        end
    end

    if not hit_wall then
        pos.x = new_x
    end

    -- Apply vertical velocity with collision
    local new_y = pos.y + vel.vy * dt

    -- Ground collision
    phys.on_ground = false
    local bottom_y = new_y + col.height / 2
    local left_col = math.floor((pos.x - col.width / 2) / world.BLOCK_SIZE)
    local right_col = math.floor((pos.x + col.width / 2 - EPSILON) / world.BLOCK_SIZE)
    local bottom_row = math.floor(bottom_y / world.BLOCK_SIZE)

    for c = left_col, right_col do
        local block_def = world:get_block_def(pos.z, c, bottom_row)
        if block_def and block_def.solid and vel.vy >= 0 then
            pos.y = bottom_row * world.BLOCK_SIZE - col.height / 2
            vel.vy = 0
            phys.on_ground = true
            new_y = pos.y
            break
        end
    end

    -- Ceiling collision
    local top_y = new_y - col.height / 2
    local top_row = math.floor(top_y / world.BLOCK_SIZE)

    for c = left_col, right_col do
        local block_def = world:get_block_def(pos.z, c, top_row)
        if block_def and block_def.solid and vel.vy < 0 then
            pos.y = (top_row + 1) * world.BLOCK_SIZE + col.height / 2
            vel.vy = 0
            new_y = pos.y
            break
        end
    end

    if not phys.on_ground then
        pos.y = new_y
    end

    -- Prevent falling through bottom
    local max_y = world.HEIGHT * world.BLOCK_SIZE
    if pos.y > max_y then
        pos.y = max_y
        vel.vy = 0
        phys.on_ground = true
    end
end

function PlayerSystem.draw(self)
    local pos = self.components.position
    local vis = self.components.visual

    local camera = Systems.get("camera")
    local camera_x, camera_y = camera:get_offset()

    love.graphics.setColor(vis.color)
    love.graphics.rectangle("fill",
        pos.x - camera_x - vis.width / 2,
        pos.y - camera_y - vis.height / 2,
        vis.width,
        vis.height)
end

function PlayerSystem.keypressed(self, key)
    -- Hotbar selection
    local num = tonumber(key)
    if num and num >= 1 and num <= self.components.inventory.hotbar_size then
        self.components.inventory.selected_slot = num
    end

    -- Layer switching
    if key == "q" then
        local target_layer = math.max(-1, self.components.position.z - 1)
        if self.can_switch_layer(self, target_layer) then
            self.components.position.z = target_layer
            self.components.layer.current_layer = target_layer
        end
    elseif key == "e" then
        local target_layer = math.min(1, self.components.position.z + 1)
        if self.can_switch_layer(self, target_layer) then
            self.components.position.z = target_layer
            self.components.layer.current_layer = target_layer
        end
    end

    if G:debug() then
        -- Debug: adjust omnitool tier
        if key == "=" or key == "+" then
            self.components.omnitool.tier = self.components.omnitool.tier + 1
        elseif key == "-" or key == "_" then
            self.components.omnitool.tier = math.max(0, self.components.omnitool.tier - 1)
        end
    end
end

function PlayerSystem.can_switch_layer(self, target_layer)
    if target_layer < -1 or target_layer > 1 then -- TODO constants for MIN and MAX layers
        return false
    end

    return not self.check_collision(self, self.components.position.x, self.components.position.y, target_layer)
end

function PlayerSystem.check_collision(self, x, y, layer)
    local world = Systems.get("world")
    local collider = self.components.collider

    local left = x - collider.width / 2
    local right = x + collider.width / 2
    local top = y - collider.height / 2
    local bottom = y + collider.height / 2

    local left_col = math.floor(left / world.BLOCK_SIZE)
    local right_col = math.floor((right - EPSILON) / world.BLOCK_SIZE)
    local top_row = math.floor(top / world.BLOCK_SIZE)
    local bottom_row = math.floor((bottom - EPSILON) / world.BLOCK_SIZE)

    for c = left_col, right_col do
        for r = top_row, bottom_row do
            local block_def = world:get_block_def(layer, c, r)
            if block_def and block_def.solid then
                return true
            end
        end
    end

    return false
end

-- Inventory management
function PlayerSystem.add_to_inventory(self, block_id, count)
    local inv = self.components.inventory
    count = count or 1

    if count <= 0 then
        return true
    end

    -- Try to stack with existing slots
    for i = 1, inv.hotbar_size do
        local slot = inv.slots[i]
        if slot and slot.block_id == block_id then
            local space = inv.max_stack - slot.count
            if space > 0 then
                local to_add = math.min(space, count)
                slot.count = slot.count + to_add
                count = count - to_add

                if count == 0 then
                    return true
                end
            end
        end
    end

    -- Find empty slots
    while count > 0 do
        local empty_slot = nil
        for i = 1, inv.hotbar_size do
            if not inv.slots[i] then
                empty_slot = i
                break
            end
        end

        if not empty_slot then
            return false
        end

        local to_add = math.min(inv.max_stack, count)
        inv.slots[empty_slot] = {
            block_id = block_id,
            count = to_add,
        }
        count = count - to_add
    end

    return true
end

function PlayerSystem.remove_from_selected(self, count)
    local inv = self.components.inventory
    count = count or 1
    local slot = inv.slots[inv.selected_slot]

    if not slot then
        return 0
    end

    local removed = math.min(count, slot.count)
    slot.count = slot.count - removed

    if slot.count <= 0 then
        inv.slots[inv.selected_slot] = nil
    end

    return removed
end

function PlayerSystem.get_selected_block_id(self)
    local inv = self.components.inventory
    local slot = inv.slots[inv.selected_slot]
    if slot then
        return slot.block_id
    end
    return nil
end

function PlayerSystem.get_position(self)
    return self.components.position.x, self.components.position.y, self.components.position.z
end

function PlayerSystem.get_omnitool_tier(self)
    return self.components.omnitool.tier
end

return PlayerSystem
