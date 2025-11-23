-- Control System
-- Manages player input and human controls

require "lib"
local log = require "lib.log"

local Systems = require "systems"
local Stance = require "components.stance"

local ControlSystem = {
    id = "control",
    priority = 19, -- Run before player system (priority 20)
    jump_pressed_last_frame = false,  -- Track jump input for edge detection
}

function ControlSystem.load(self) end

function ControlSystem.update(self, dt)
    local player = Systems.get("player")
    local world = Systems.get("world")
    local pos = player.components.position
    local vel = player.components.velocity
    local stance = player.components.stance
    local col = player.components.collider
    local vis = player.components.visual

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
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        vel.vx = -player.MOVE_SPEED
        -- Check if shift is pressed and player is on ground
        if on_ground and (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) then
            if player:has_stamina(0) then  -- Only run if has any stamina
                vel.vx = vel.vx * 2
                is_running = true
            end
        end
    end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        if stance.crouched then
            vel.vx = player.MOVE_SPEED / 2
        else
            vel.vx = player.MOVE_SPEED
            -- Check if shift is pressed and player is on ground
            if on_ground and (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) then
                if player:has_stamina(0) then  -- Only run if has any stamina
                    vel.vx = vel.vx * 2
                    is_running = true
                end
            end
        end
    end
    
    -- Consume stamina while running
    if is_running then
        player:consume_stamina(player.STAMINA_RUN_COST * dt)
    end

    -- Jump handling - only when on ground and not crouching
    local jump_pressed = love.keyboard.isDown("w") or love.keyboard.isDown("space") or love.keyboard.isDown("up")
    if jump_pressed and not self.jump_pressed_last_frame and on_ground then
        -- Check if player has enough stamina to jump
        if player:has_stamina(player.STAMINA_JUMP_COST) then
            if stance.crouched then
                vel.vy = -player.JUMP_FORCE
            else
                vel.vy = -player.JUMP_FORCE
            end
            stance.current = Stance.JUMPING
            -- Consume stamina for jumping
            player:consume_stamina(player.STAMINA_JUMP_COST)
        end
    end
    self.jump_pressed_last_frame = jump_pressed
end

function ControlSystem.keypressed(self, key)
    local player = Systems.get("player")

    -- Hotbar selection
    local num = tonumber(key)
    if num and num >= 1 and num <= player.components.inventory.hotbar_size then
        player.components.inventory.selected_slot = num
    end

    -- Layer switching
    if key == "q" then
        local target_layer = math.max(-1, player.components.position.z - 1)
        if player.can_switch_layer(player, target_layer) then
            player.components.position.z = target_layer
            player.components.layer.current_layer = target_layer
        end
    elseif key == "e" then
        local target_layer = math.min(1, player.components.position.z + 1)
        if player.can_switch_layer(player, target_layer) then
            player.components.position.z = target_layer
            player.components.layer.current_layer = target_layer
        end
    end
end

return ControlSystem
