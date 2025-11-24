-- Control System
-- Manages player input and human controls

require "lib"
local log = require "lib.log"

local Object = require "core.object"
local Systems = require "core.systems"
local Stance = require "components.stance"

local ControlSystem = Object.new {
    id = "control",
    priority = 19, -- Run before player system (priority 20)
    jump_pressed_last_frame = false,  -- Track jump input for edge detection
}

function ControlSystem.update(self, dt)
    local chat = Systems.get("chat")
    if chat.in_input_mode then
        return
    end

    local player = Systems.get("player")
    local world = Systems.get("world")
    local pos = player.position
    local vel = player.velocity
    local stance = player.stance
    local col = player.collider
    local vis = player.visual

    -- Check if on ground first
    local on_ground = player:is_on_ground()

    -- Handle crouching toggle (only when on ground)
    local is_crouching = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")

    if is_crouching and not stance.crouched then
        -- Switch to crouching (only when on ground)
        stance.current = Stance.STANDING
        stance.crouched = true
        col.height = BLOCK_SIZE * 1
        vis.height = BLOCK_SIZE * 1
        -- Adjust position to keep bottom aligned
        pos.y = pos.y + BLOCK_SIZE / 2
    elseif not is_crouching and stance.crouched then
        -- Try to stand up - check clearance
        if player:can_stand_up() then
            stance.current = Stance.STANDING
            stance.crouched = false
            col.height = BLOCK_SIZE * 2
            vis.height = BLOCK_SIZE * 2
            -- Adjust position to keep bottom aligned
            pos.y = pos.y - BLOCK_SIZE / 2
        end
    end

    -- Horizontal movement
    vel.vx = 0
    local is_running = false
    local is_shift_pressed = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")

    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        vel.vx = -player.MOVE_SPEED
    end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        vel.vx = player.MOVE_SPEED
    end

    -- Apply movement modifiers
    if vel.vx ~= 0 then
        if stance.crouched then
            -- Crouching slows movement by half
            vel.vx = vel.vx / 2
        elseif on_ground and is_shift_pressed and player:has_stamina(player.STAMINA_RUN_COST * dt) then
            -- Running doubles speed (only when on ground and not crouched)
            vel.vx = vel.vx * 2
            is_running = true
        end
    end

    -- Consume stamina while running
    if is_running then
        player:consume_stamina(player.STAMINA_RUN_COST * dt)
    end

    -- Jump handling - only when on ground
    local jump_pressed = love.keyboard.isDown("w") or love.keyboard.isDown("space") or love.keyboard.isDown("up")
    if jump_pressed and not self.jump_pressed_last_frame and on_ground then
        -- Check if player has enough stamina to jump
        if player:has_stamina(player.STAMINA_JUMP_COST) then
            vel.vy = -player.JUMP_FORCE
            stance.current = Stance.JUMPING
            -- Consume stamina for jumping
            player:consume_stamina(player.STAMINA_JUMP_COST)
        end
    end
    self.jump_pressed_last_frame = jump_pressed
end

function ControlSystem.keypressed(self, key)
    local chat = Systems.get("chat")
    if chat.in_input_mode then
        return
    end

    local player = Systems.get("player")

    -- Hotbar selection
    local num = tonumber(key)
    if num and num >= 1 and num <= player.inventory.hotbar_size then
        player.inventory.selected_slot = num
    end

    -- Layer switching
    if key == "q" then
        local target_layer = math.max(-1, player.position.z - 1)
        if player.can_switch_layer(player, target_layer) then
            player.position.z = target_layer
            player.layer.current_layer = target_layer
        end
    elseif key == "e" then
        local target_layer = math.min(1, player.position.z + 1)
        if player.can_switch_layer(player, target_layer) then
            player.position.z = target_layer
            player.layer.current_layer = target_layer
        end
    end
end

return ControlSystem
