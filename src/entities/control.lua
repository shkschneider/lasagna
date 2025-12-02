local Love = require "core.love"
local Object = require "core.object"
local Stance = require "src.data.stance"

local Control = {
    MOVE_SPEED = 150, -- unit?
    JUMP_FORCE = 300, -- unit?
    STAMINA_RUN_COST = 2.5,  -- per second
    STAMINA_JUMP_COST = 5,   -- per jump
    JETPACK_STAMINA_COST = 2,  -- per second
    JETPACK_THRUST_FORCE = 200,
}

function Control.new()
    local control = Object {
        id = "control",
        priority = 19, -- Run before player system (priority 20)
        sprinting = false,
        jetpack_thrusting = false,
    }
    return setmetatable(control, { __index = Control })
end

-- Check if player has enough stamina
function Control.has_stamina(self, amount)
    return G.player.stamina and G.player.stamina.current >= amount
end

-- Consume stamina from player
function Control.consume_stamina(self, amount)
    if not G.player.stamina then
        return false
    end

    if G.player.stamina.current >= amount then
        G.player.stamina.current = math.max(0, G.player.stamina.current - amount)
        return true
    end

    return false
end

function Control.update(self, dt)
    if G.chat.in_input_mode then return end
    -- if G.player.inventory_open then return end

    local pos = G.player.position
    local vel = G.player.velocity
    local stance = G.player.stance

    -- Use cached ground state from previous frame's physics resolution
    -- This ensures consistent on_ground detection since Control runs before Player
    local on_ground = G.player.on_ground

    -- Helper to stand up from crouch
    local function try_stand_up()
        if stance.crouched and G.player:can_stand_up() then
            stance.current = Stance.STANDING
            stance.crouched = false
            G.player.height = BLOCK_SIZE * 2
            -- Adjust position to keep bottom aligned
            pos.y = pos.y - BLOCK_SIZE / 2
            -- Scale velocity to maintain consistent movement speed when standing up from crouch
            -- When crouched, vertical velocity is applied at 0.5x, so we need to halve velocity
            -- when standing to prevent sudden speed increase
            if not on_ground then
                vel.y = vel.y * 0.5
            end
            return true
        end
        return false
    end

    -- Handle crouching toggle (only when on ground)
    local is_crouching = love.keyboard.isDown("s") or love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")

    if is_crouching and not stance.crouched and on_ground then
        -- Switch to crouching (only when on ground)
        stance.current = Stance.STANDING
        stance.crouched = true
        G.player.height = BLOCK_SIZE * 1
        -- Adjust position to keep bottom aligned
        pos.y = pos.y + BLOCK_SIZE / 2
    elseif (not is_crouching or not on_ground) and stance.crouched then
        -- Try to stand up when releasing crouch key or leaving ground
        try_stand_up()
    end

    -- Horizontal movement
    vel.x = 0
    self.sprinting = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")

    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        vel.x = -self.MOVE_SPEED * (self.sprinting and 1.5 or 1)
    end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        vel.x = self.MOVE_SPEED * (self.sprinting and 1.5 or 1)
    end

    -- Apply movement modifiers
    if vel.x ~= 0 then
        if stance.crouched then
            -- Crouching slows movement by half
            vel.x = vel.x / 2
        elseif on_ground and is_running and self:has_stamina(self.STAMINA_RUN_COST * dt) then
            -- Running doubles speed (only when on ground and not crouched)
            vel.x = vel.x * 1.5
            self.sprinting = true
        end
    end

    -- Consume stamina while running
    if is_running then
        self:consume_stamina(self.STAMINA_RUN_COST * dt)
    end

    -- Jump handling - only when on ground and not already jumping
    local jump_pressed = love.keyboard.isDown("w") or love.keyboard.isDown("space") or love.keyboard.isDown("up")
    if jump_pressed and stance.current ~= Stance.JUMPING and on_ground then
        vel.y = -self.JUMP_FORCE
        stance.current = Stance.JUMPING
        -- Sprint jump: 1.5x horizontal velocity, consumes stamina
        if self.sprinting and self:has_stamina(self.STAMINA_JUMP_COST) then
            vel.x = vel.x * 1.5
            self:consume_stamina(self.STAMINA_JUMP_COST)
        end
    end

    -- Jetpack handling - only when in air and holding space
    local jump_pressed = love.keyboard.isDown("space")
    if G.player.jetpack and jump_pressed and not on_ground then
        local stamina_cost = self.JETPACK_STAMINA_COST * dt
        if self:has_stamina(stamina_cost) then
            self:consume_stamina(stamina_cost)
            -- Jetpack provides upward thrust (negative velocity = upward)
            -- Always apply thrust in upward direction only
            vel.y = vel.y - self.JETPACK_THRUST_FORCE * dt
            self.jetpack_thrusting = true
        else
            self.jetpack_thrusting = false
        end
        if stance.crouched then
            try_stand_up()
        end
    else
        self.jetpack_thrusting = false
    end

    Love.update(self, dt)
end

function Control.keypressed(self, key)
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

return Control
