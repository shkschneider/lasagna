local Object = require("lib.object")

--- MovementComponent: Handles player movement physics based on intents
--- This component reads player.intent and updates player.vx/player.vy/player.movement_state
--- but does NOT call world movement methods (that remains the caller's responsibility).
---
--- Usage:
---   local Movement = require("entities.components.movement")
---   player.movement = Movement.new(player, { max_speed = 6, accel = 60 })
---   -- In update loop:
---   player.movement:update(dt)
---   -- Then apply movement with world physics:
---   Movements.move(player, player.vx * dt, player.vy * dt, world)

local Movement = Object {}

--- Creates a new Movement component
--- @param player table The player entity to attach to
--- @param opts table Optional configuration: max_speed, accel
--- @return table Movement component instance
function Movement:new(player, opts)
    opts = opts or {}

    -- Reference to the player entity
    self.player = player

    -- Configuration (with defaults from constants)
    self.max_speed = opts.max_speed or C.MAX_SPEED
    self.accel = opts.accel or C.MOVE_ACCEL
end

--- Updates player velocity based on intent and physics
--- Reads: player.intent (left, right, jump, crouch, run)
--- Writes: player.vx, player.vy, player.movement_state
--- @param dt number Delta time in seconds
function Movement:update(dt)
    local player = self.player

    -- Defensive: ensure required fields exist
    if not player.intent then return end
    if not player.vx then player.vx = 0 end
    if not player.vy then player.vy = 0 end

    -- Check if player has movement_state (grounded check)
    local function is_grounded()
        if player.movement_state then
            return player.movement_state == "GROUNDED"
        elseif player.on_ground ~= nil then
            return player.on_ground
        end
        return false
    end

    local function is_crouching()
        if player.stance then
            return player.stance == "CROUCHING"
        elseif player.crouching ~= nil then
            return player.crouching
        end
        return player.intent.crouch or false
    end

    -- Calculate effective speed limits
    local MAX_SPEED = self.max_speed
    local accel = self.accel

    if player.intent.run then
        MAX_SPEED = (C.RUN_SPEED_MULT or 1.6) * MAX_SPEED
        accel = (C.RUN_ACCEL_MULT or 1.2) * accel
    end

    if is_crouching() then
        MAX_SPEED = math.min(MAX_SPEED, C.CROUCH_MAX_SPEED or 3)
    end

    if not is_grounded() then
        accel = accel * (C.AIR_ACCEL_MULT or 0.35)
    end

    -- Horizontal movement
    local dir = 0
    if player.intent.left then dir = dir - 1 end
    if player.intent.right then dir = dir + 1 end
    local target_vx = dir * MAX_SPEED

    if dir ~= 0 then
        -- Accelerate toward target
        local use_accel = accel
        if is_crouching() then use_accel = accel * 0.6 end

        if player.vx < target_vx then
            player.vx = math.min(target_vx, player.vx + use_accel * dt)
        elseif player.vx > target_vx then
            player.vx = math.max(target_vx, player.vx - use_accel * dt)
        end
    else
        -- Deceleration (friction)
        local friction
        if is_crouching() then
            friction = C.CROUCH_DECEL or 120
        elseif is_grounded() then
            friction = C.GROUND_FRICTION or 30
        else
            friction = C.AIR_FRICTION or 1.5
        end

        local dec = friction * dt
        if math.abs(player.vx) <= dec then
            player.vx = 0
        else
            player.vx = player.vx - (player.vx > 0 and 1 or -1) * dec
        end
    end

    -- Jumping
    if player.intent.jump then
        if is_grounded() then
            player.vy = C.JUMP_SPEED or -10
            if player.movement_state then
                player.movement_state = "AIRBORNE"
            end
            if player.on_ground ~= nil then
                player.on_ground = false
            end
        end
        player.intent.jump = false
    end

    -- Gravity
    player.vy = player.vy + (C.GRAVITY or 20) * dt
end

return Movement
