local Object = require("lib.object")

--- GravityComponent: Applies gravity to entities
--- This component updates entity.vy based on C.GRAVITY
---
--- Usage:
---   local Gravity = require("entities.components.gravity")
---   entity.gravity = Gravity(entity)
---   -- In update loop:
---   entity.gravity:update(dt)

local Gravity = Object {}

--- Creates a new Gravity component
--- @param entity table The entity to attach to (must have vy field)
--- @param opts table Optional configuration: gravity_scale (default 1.0)
--- @return table Gravity component instance
function Gravity:new(entity, opts)
    opts = opts or {}
    
    -- Reference to the entity
    self.entity = entity
    
    -- Gravity scale multiplier (1.0 = normal gravity, 0.5 = half gravity, etc.)
    self.gravity_scale = opts.gravity_scale or 1.0
end

--- Applies gravity to the entity's vertical velocity
--- Reads: C.GRAVITY
--- Writes: entity.vy
--- @param dt number Delta time in seconds
function Gravity:update(dt)
    local entity = self.entity
    
    -- Ensure entity has vy field
    if not entity.vy then
        entity.vy = 0
    end
    
    -- Apply gravity
    entity.vy = entity.vy + (C.GRAVITY or 20) * self.gravity_scale * dt
end

return Gravity
