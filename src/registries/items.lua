-- Item Registry
-- Items register themselves here for game expansion

local ItemsRegistry = {}

-- Register a new block type
function ItemsRegistry.register(self, definition)
    definition.id = definition.id or id()
    assert(definition.name)
    assert(not self:exists(definition.id))
    self[definition.id] = definition
    return definition.id
end

-- Get a block prototype by ID
function ItemsRegistry.get(self, id)
    return self[id]
end

-- Get all registered blocks
function ItemsRegistry.get_all(self)
    return self
end

-- Iterate over all blocks
function ItemsRegistry.iterate(self)
    return pairs(self)
end

-- Check if a block ID exists
function ItemsRegistry.exists(self, id)
    return self[id] ~= nil
end

return ItemsRegistry
