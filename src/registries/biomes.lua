-- Biome Registry
-- Biomes register themselves here for game expansion

local BiomesRegistry = {}

-- Register a new biome
function BiomesRegistry.register(self, definition)
    assert(definition.id, "Biome must have an id")
    assert(not self:exists(definition.id), "Biome already exists: " .. tostring(definition.id))
    self[definition.id] = definition
    self[definition.name] = definition
    assert(definition.name, "Biome must have a name")
    definition.temperature = definition.temperature or "normal"
    definition.humidity = definition.humidity or "normal"
    assert(definition.surface and definition.subsurface, "Biome must have surface defined")
    assert(definition.underground, "Biome must have underground defined")
    -- TODO assert sum of weight == 100
    return definition.id
end

-- Get a biome by ID or name
function BiomesRegistry.get(self, id_or_name)
    return self[id_or_name]
end

-- Get all registered biomes (by ID only, exclude name indexes)
function BiomesRegistry.get_all(self)
    local biomes = {}
    for key, biome in pairs(self) do
        if type(key) == "number" then
            table.insert(biomes, biome)
        end
    end
    table.sort(biomes, function(a, b) return a.id < b.id end)
    return biomes
end

-- Iterate over all biomes (by ID only)
function BiomesRegistry.iterate(self)
    local biomes = self:get_all()
    local i = 0
    return function()
        i = i + 1
        local biome = biomes[i]
        if biome then
            return biome.id, biome
        end
    end
end

-- Check if a biome ID or name exists
function BiomesRegistry.exists(self, id_or_name)
    return self[id_or_name] ~= nil
end

-- Get biome count
function BiomesRegistry.count(self)
    local count = 0
    for key, _ in pairs(self) do
        if type(key) == "number" then
            count = count + 1
        end
    end
    return count
end

return BiomesRegistry
