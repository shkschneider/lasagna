local VectorComponent = {}

function VectorComponent.new(x, y)
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
    if entity and entity.position then
        entity.position.x = entity.position.x + self.vx * dt
        entity.position.y = entity.position.y + self.vy * dt
    end
end

return VectorComponent
