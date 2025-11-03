local Object = require("lib.object")
local log = require("lib.log")

local Lighting = Object {}

function Lighting:new()
    -- Light sources: list of {x, y, z, intensity, radius}
    self.light_sources = {}
    -- Ambient light level (0.0 to 1.0)
    self.ambient_light = 1.0
end

-- Add a light source
-- @param x: world x position (in blocks)
-- @param y: world y position (in blocks)
-- @param z: layer
-- @param intensity: brightness (0.0 to 1.0)
-- @param radius: how far the light reaches (in blocks)
function Lighting:add_light(x, y, z, intensity, radius)
    table.insert(self.light_sources, {
        x = x,
        y = y,
        z = z,
        intensity = intensity or 1.0,
        radius = radius or 10,
    })
end

-- Remove all light sources
function Lighting:clear_lights()
    self.light_sources = {}
end

-- Set ambient light level based on time of day
-- @param level: 0.0 (complete darkness) to 1.0 (full brightness)
function Lighting:set_ambient_light(level)
    self.ambient_light = math.max(0.0, math.min(1.0, level))
end

-- Calculate light level at a specific position
-- @param x: world x position (in blocks)
-- @param y: world y position (in blocks)
-- @param z: layer
-- @return light level (0.0 to 1.0)
function Lighting:get_light_level(x, y, z)
    local max_light = self.ambient_light
    
    -- Check all light sources
    for _, light in ipairs(self.light_sources) do
        -- Only consider lights on the same layer
        if light.z == z then
            local dx = x - light.x
            local dy = y - light.y
            local distance = math.sqrt(dx * dx + dy * dy)
            
            if distance < light.radius then
                -- Quadratic falloff: light decreases with square of distance
                local falloff = math.pow(1.0 - (distance / light.radius), 2)
                local light_contribution = light.intensity * falloff
                
                -- Take the maximum light level from any source
                max_light = math.max(max_light, light_contribution)
            end
        end
    end
    
    return math.max(0.0, math.min(1.0, max_light))
end

-- Update lighting system (called each frame)
function Lighting:update(dt)
    -- Future: could add dynamic lights, flickering, etc.
end

return Lighting
