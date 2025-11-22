-- Block Registry
-- Blocks register themselves here for game expansion

local BlocksRegistry = {
    blocks = {},
    id_counter = 0,
}

-- Register a new block type
function BlocksRegistry.register(self, definition)
    -- Auto-assign ID if not provided
    if not definition.id then
        definition.id = self.id_counter
        self.id_counter = self.id_counter + 1
    else
        -- Update counter if ID is higher
        if definition.id >= self.id_counter then
            self.id_counter = definition.id + 1
        end
    end

    -- Store block by ID
    self.blocks[definition.id] = definition

    return definition.id
end

-- Get a block prototype by ID
function BlocksRegistry.get(self, id)
    return self.blocks[id]
end

-- Get all registered blocks
function BlocksRegistry.get_all(self)
    return self.blocks
end

-- Iterate over all blocks
function BlocksRegistry.iterate(self)
    return pairs(self.blocks)
end

-- Check if a block ID exists
function BlocksRegistry.exists(self, id)
    return self.blocks[id] ~= nil
end

return BlocksRegistry
