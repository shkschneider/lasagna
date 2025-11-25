-- Block Registry
-- Blocks register themselves here for game expansion

local BlocksRegistry = {}

-- Register a new block type
function BlocksRegistry.register(self, definition)
    definition.id = definition.id or id()
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

-- Get all blocks with ore generation data
function BlocksRegistry.get_ore_blocks(self)
    local ore_blocks = {}
    for id, block in pairs(self) do
        -- Skip registry functions and only include blocks with ore_gen metadata
        if type(block) == "table" and type(id) == "number" and block.ore_gen then
            table.insert(ore_blocks, block)
        end
    end
    -- Sort by block ID to ensure consistent, deterministic ordering
    table.sort(ore_blocks, function(a, b) return a.id < b.id end)
    return ore_blocks
end

return BlocksRegistry
