-- Drop System
-- Manages drop entities (items on ground)

require "lib"

local Object = require "core.object"
local Drop = require "components.drop"

local DropSystem = Object.new {
    id = "drop",
    priority = 70,
    entities = {},
}

function DropSystem.load(self)
    self.entities = {}
end

function DropSystem.create_drop(self, x, y, layer, block_id, count)
    local entity = Drop.create_entity(x, y, layer, block_id, count)
    table.insert(self.entities, entity)
    return entity
end

function DropSystem.update(self, dt)
    -- Update all drop entities and remove marked ones
    for i = #self.entities, 1, -1 do
        local ent = self.entities[i]
        Object.update(ent, dt)
        
        -- Remove if marked for removal
        if ent.remove_me then
            table.remove(self.entities, i)
        end
    end
end

function DropSystem.draw(self)
    -- Draw all drop entities
    for _, ent in ipairs(self.entities) do
        Object.draw(ent)
    end
end

return DropSystem
