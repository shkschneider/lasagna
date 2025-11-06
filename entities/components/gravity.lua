local Object = require("lib.object")

local Gravity = Object {}

function Gravity:new(entity, opts)
    assert(entity)
    opts = opts or {}
    self.entity = entity
    self.gravity_scale = opts.gravity_scale or 1.0
end

function Gravity:update(dt)
    local entity = self.entity
    if not entity.vy then
        entity.vy = 0
    end

    -- In DEBUG mode, disable gravity for the player (flying mode)
    if G.debug and entity.navigation then
        -- This is the player (has navigation component)
        -- Don't apply gravity in debug mode
        return
    end

    entity.vy = entity.vy + C.GRAVITY * self.gravity_scale * dt
end

return Gravity
