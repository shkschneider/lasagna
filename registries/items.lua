-- Item Registry
-- Items register themselves here for game expansion

local ItemsRegistry = {
    items = {},
    id_counter = 0,
}

-- Register a new block type
function ItemsRegistry.register(self, definition)
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
    self.items[definition.id] = definition

    return definition.id
end

-- Get a block prototype by ID
function ItemsRegistry.get(self, id)
    return self.items[id]
end

-- Get all registered blocks
function ItemsRegistry.get_all(self)
    return self.items
end

-- Iterate over all blocks
function ItemsRegistry.iterate(self)
    return pairs(self.items)
end

-- Check if a block ID exists
function ItemsRegistry.exists(self, id)
    return self.items[id] ~= nil
end

return ItemsRegistry
