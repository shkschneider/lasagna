local Object = require("lib.object")

local Movement = Object {}

function Movement:new(entity, opts)
    assert(entity)
    opts = opts or {}
    self.entity = entity
    self.max_speed = opts.max_speed or C.MAX_SPEED
    self.accel = opts.accel or C.MOVE_ACCEL
end

function Movement:update(dt)
    local entity = self.entity
    if not entity.intent then return end
    if not entity.vx then entity.vx = 0 end
    if not entity.vy then entity.vy = 0 end
    local function is_grounded()
        if entity.movement_state then
            return entity.movement_state == "GROUNDED"
        elseif entity.on_ground ~= nil then
            return entity.on_ground
        end
        return false
    end
    local function is_crouching()
        if entity.stance then
            return entity.stance == "CROUCHING"
        elseif entity.crouching ~= nil then
            return entity.crouching
        end
        return entity.intent.crouch or false
    end
    local MAX_SPEED = self.max_speed
    local accel = self.accel
    if entity.intent.run then
        MAX_SPEED = C.RUN_SPEED_MULT * MAX_SPEED
        accel = C.RUN_ACCEL_MULT * accel
    end
    if is_crouching() then
        MAX_SPEED = math.min(MAX_SPEED, C.CROUCH_MAX_SPEED)
    end
    if not is_grounded() then
        accel = accel * C.AIR_ACCEL_MULT
    end
    -- Horizontal movement
    local dir = 0
    if entity.intent.left then dir = dir - 1 end
    if entity.intent.right then dir = dir + 1 end
    local target_vx = dir * MAX_SPEED
    if dir ~= 0 then
        -- Accelerate toward target
        local use_accel = accel
        if is_crouching() then use_accel = accel * 0.6 end
        if entity.vx < target_vx then
            entity.vx = math.min(target_vx, entity.vx + use_accel * dt)
        elseif entity.vx > target_vx then
            entity.vx = math.max(target_vx, entity.vx - use_accel * dt)
        end
    else
        -- Deceleration (friction)
        local friction
        if is_crouching() then
            friction = C.CROUCH_DECEL
        elseif is_grounded() then
            friction = C.GROUND_FRICTION
        else
            friction = C.AIR_FRICTION
        end
        local dec = friction * dt
        if math.abs(entity.vx) <= dec then
            entity.vx = 0
        else
            entity.vx = entity.vx - (entity.vx > 0 and 1 or -1) * dec
        end
    end
    -- Jumping
    if entity.intent.jump then
        if is_grounded() then
            entity.vy = C.JUMP_SPEED
            if entity.movement_state then
                entity.movement_state = "AIRBORNE"
            end
            if entity.on_ground ~= nil then
                entity.on_ground = false
            end
        end
        entity.intent.jump = false
    end
    -- Gravity
    entity.vy = entity.vy + C.GRAVITY * dt
end

return Movement
