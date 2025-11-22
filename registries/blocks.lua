-- Block Registry
-- Blocks register themselves here for game expansion

require "lib"

local BlocksRegistry = {}

-- Register a new block type
function BlocksRegistry.register(self, definition)
    definition.id = definition.id or uuid()
    assert(not self:exists(definition.id))
    self[definition.id] = definition
    return definition.id
end

-- Get a block prototype by ID
function BlocksRegistry.get(self, id)
    return self[id]
end

-- Get all registered blocks
function BlocksRegistry.get_all(self)
    return self
end

-- Iterate over all blocks
function BlocksRegistry.iterate(self)
    return pairs(self)
end

-- Check if a block ID exists
function BlocksRegistry.exists(self, id)
    return self[id] ~= nil
end

return BlocksRegistry
