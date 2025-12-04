local Love = require "core.love"
local Object = require "core.object"

local Entities = Object {
    id = "entities",
    priority = 60,  -- After player (20), before interface
    all = {},
}

-- Initialize the entity system
function Entities.load(self)
    self.all = {}
    Love.load(self)
end

-- Add an entity to the manager
function Entities.add(self, entity)
    table.insert(self.all, entity)
    return entity
end

-- Get entities by type
function Entities.getByType(self, entity_type)
    local result = {}
    for _, ent in ipairs(self.all) do
        if ent.type == entity_type then
            table.insert(result, ent)
        end
    end
    return result
end

-- Update all entities
function Entities.update(self, dt)
    for i = #self.all, 1, -1 do
        local ent = self.all[i]
        if ent then -- might have despawned already
            -- Call entity update method
            if type(ent.update) == "function" then
                ent:update(dt)
            end

            -- Remove dead entities
            if ent.dead then
                table.remove(self.all, i)
            end
        end
    end
    -- Do NOT Love.update(self, dt)
end

-- Draw all entities
function Entities.draw(self)
    local camera_x, camera_y = G.camera:get_offset()

    for _, ent in ipairs(self.all) do
        if ent.draw then
            ent:draw(camera_x, camera_y)
        end
        Love.draw(ent)
    end
end

return Entities
