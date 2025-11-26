-- World Registry
-- Features register themselves here for world generation

local WorldRegistry = {}

-- Register a new world feature
function WorldRegistry.register(self, definition)
    assert(definition.id, "Feature must have an id")
    assert(definition.layers, "Feature must have layers")
    assert(definition.shapes, "Feature must have shapes")
    assert(not self:exists(definition.id), "Feature already exists: " .. tostring(definition.id))
    self[definition.id] = definition
    return definition.id
end

-- Get a feature by ID
function WorldRegistry.get(self, id)
    return self[id]
end

-- Get all registered features
-- Returns a shallow copy to prevent external modification
function WorldRegistry.get_all(self)
    local copy = {}
    for id, feature in pairs(self) do
        if type(feature) == "table" and type(id) == "string" then
            copy[id] = feature
        end
    end
    return copy
end

-- Iterate over all features
function WorldRegistry.iterate(self)
    return pairs(self)
end

-- Check if a feature ID exists
function WorldRegistry.exists(self, id)
    return self[id] ~= nil
end

-- Get all features for generation
function WorldRegistry.get_features(self)
    local features = {}
    for id, feature in pairs(self) do
        -- Skip registry functions and only include feature tables
        if type(feature) == "table" and type(id) == "string" then
            table.insert(features, feature)
        end
    end
    return features
end

return WorldRegistry
