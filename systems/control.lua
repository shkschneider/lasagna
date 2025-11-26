local Love = require "core.love"
local Object = require "core.object"
local StanceComponent = require "components.stance"

local ControlSystem = Object {
    id = "control",
    priority = 19, -- Run before player system (priority 20)
    -- Stamina constants
    STAMINA_RUN_COST = 2.5,  -- per second
    STAMINA_JUMP_COST = 5,   -- per jump
}

-- Check if player has enough stamina
function ControlSystem.has_stamina(self, amount)
    return G.player.stamina and G.player.stamina.current >= amount
end

-- Consume stamina from player
function ControlSystem.consume_stamina(self, amount)
    if not G.player.stamina then
        return false
    end

    if G.player.stamina.current >= amount then
        G.player.stamina.current = math.max(0, G.player.stamina.current - amount)
        return true
    end

    return false
end

function ControlSystem.update(self, dt)
    if G.chat.in_input_mode then
        return
    end

    local pos = G.player.position
    local vel = G.player.velocity
    local stance = G.player.stance

    -- Check if on ground first
    local on_ground = G.player:is_on_ground()

    -- Handle crouching toggle (only when on ground)
    local is_crouching = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")

    if is_crouching and not stance.crouched then
        -- Switch to crouching (only when on ground)
        stance.current = StanceComponent.STANDING
        stance.crouched = true
        G.player.height = BLOCK_SIZE * 1
        -- Adjust position to keep bottom aligned
        pos.y = pos.y + BLOCK_SIZE / 2
    elseif not is_crouching and stance.crouched then
        -- Try to stand up - check clearance
        if G.player:can_stand_up() then
            stance.current = StanceComponent.STANDING
            stance.crouched = false
            G.player.height = BLOCK_SIZE * 2
            -- Adjust position to keep bottom aligned
            pos.y = pos.y - BLOCK_SIZE / 2
        end
    end

    -- Horizontal movement
    vel.x = 0
    local is_running = false
    local is_shift_pressed = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")

    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        vel.x = -G.player.MOVE_SPEED
    end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        vel.x = G.player.MOVE_SPEED
    end

    -- Apply movement modifiers
    if vel.x ~= 0 then
        if stance.crouched then
            -- Crouching slows movement by half
            vel.x = vel.x / 2
        elseif on_ground and is_shift_pressed and self:has_stamina(ControlSystem.STAMINA_RUN_COST * dt) then
            -- Running doubles speed (only when on ground and not crouched)
            vel.x = vel.x * 2
            is_running = true
        end
    end

    -- Consume stamina while running
    if is_running then
        self:consume_stamina(ControlSystem.STAMINA_RUN_COST * dt)
    end

    -- Jump handling - only when on ground
    local jump_pressed = love.keyboard.isDown("w") or love.keyboard.isDown("space") or love.keyboard.isDown("up")
    if jump_pressed and not stance.current ~= StanceComponent.JUMPING and on_ground then
        if stance.crouched then
            -- Crouched jump: reduced height, no stamina cost
            vel.y = -G.player.JUMP_FORCE / 2
            stance.current = StanceComponent.JUMPING
        elseif self:has_stamina(ControlSystem.STAMINA_JUMP_COST) then
            -- Full jump: requires and consumes stamina
            vel.y = -G.player.JUMP_FORCE
            stance.current = StanceComponent.JUMPING
            self:consume_stamina(ControlSystem.STAMINA_JUMP_COST)
        else
            -- Low stamina fallback: crouched-height jump, no stamina cost
            vel.y = -G.player.JUMP_FORCE / 2
            stance.current = StanceComponent.JUMPING
        end
    end

    Love.update(self, dt)
end

function ControlSystem.keypressed(self, key)
    if G.chat.in_input_mode then
        return
    end

    -- Hotbar selection
    local num = tonumber(key)
    if num and num >= 1 and num <= G.player.hotbar.size then
        G.player.hotbar.selected_slot = num
    end

    -- Layer switching (using position.z as layer)
    if key == "q" then
        local target_layer = math.max(-1, G.player.position.z - 1)
        if G.player:can_switch_layer(target_layer) then
            G.player.position.z = target_layer
        end
    elseif key == "e" then
        local target_layer = math.min(1, G.player.position.z + 1)
        if G.player:can_switch_layer(target_layer) then
            G.player.position.z = target_layer
        end
    end

    Love.keypressed(self, key)
end

return ControlSystem
