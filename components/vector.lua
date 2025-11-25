local VectorComponent = {}

-- For position vectors: new(x, y, z)
-- For velocity vectors: new(x, y) where x=vx, y=vy
function VectorComponent.new(x, y, z)
    return {
        __index = VectorComponent,
        id = "vector",
        priority = 20,  -- after physics
        x = x or 0,
        y = y or 0,
        z = z or LAYER_DEFAULT,
        tostring = function(self)
            return string.format("%d,%d,%d", self.x, self.y, self.z)
        end
    }
end

function VectorComponent.update(self, dt, entity)
    -- Apply velocity to position component if it exists
    -- Velocity uses x and y as horizontal and vertical components
    if entity and entity.position then
        entity.position.x = entity.position.x + self.x * dt
        entity.position.y = entity.position.y + self.y * dt
    end
end

return VectorComponent
