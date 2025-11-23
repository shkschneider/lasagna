-- Control System
-- Manages player input and human controls

require "lib"
local log = require "lib.log"

local Systems = require "systems"
local Stance = require "components.stance"

local ControlSystem = {
    id = "control",
    priority = 19, -- Run before player system (priority 20)
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

    if is_crouching and stance.current ~= Stance.CROUCHING and on_ground then
        -- Switch to crouching (only when on ground)
        stance.current = Stance.CROUCHING
        col.height = world.BLOCK_SIZE
        vis.height = world.BLOCK_SIZE
        -- Adjust position to keep bottom aligned
        pos.y = pos.y + world.BLOCK_SIZE / 2
    elseif not is_crouching and stance.current == Stance.CROUCHING then
        -- Try to stand up - check clearance
        if player:can_stand_up() then
            stance.current = Stance.STANDING
            col.height = world.BLOCK_SIZE * 2
            vis.height = world.BLOCK_SIZE * 2
            -- Adjust position to keep bottom aligned
            pos.y = pos.y - world.BLOCK_SIZE / 2
        end
    end

    -- Horizontal movement
    vel.vx = 0
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        vel.vx = -player.MOVE_SPEED
    end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        if stance.current == Stance.CROUCHING then
            vel.vx = player.MOVE_SPEED / 2
        else
            vel.vx = player.MOVE_SPEED
        end
    end

    -- Jump handling - only when on ground and not crouching
    if (love.keyboard.isDown("w") or love.keyboard.isDown("space") or love.keyboard.isDown("up")) and on_ground then
        if stance.current == Stance.CROUCHING then
            vel.vy = -player.JUMP_FORCE / 2
        else
            vel.vy = -player.JUMP_FORCE
        end
        stance.current = Stance.JUMPING
    end
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

    if G:debug() then
        -- Debug: adjust omnitool tier
        if key == "=" or key == "+" then
            player.components.omnitool.tier = player.components.omnitool.tier + 1
        elseif key == "-" or key == "_" then
            player.components.omnitool.tier = math.max(0, player.components.omnitool.tier - 1)
        end
    end
end

return ControlSystem
