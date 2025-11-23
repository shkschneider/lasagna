-- WorldData component
-- World dimensions and storage
-- World is infinite horizontally; uses chunk-based storage (64 columns) but column-based generation

local WorldData = {}

function WorldData.new(seed, height)
    return {
        id = "worlddata",
        seed = seed or math.floor(love.math.random() * INFINITY),
        height = height or 512,
        -- Chunk-based storage: chunks[z][chunk_index] contains 64 columns
        -- No horizontal width limit - columns are generated on demand
        chunks = {
            [-1] = {},
            [0] = {},
            [1] = {},
        },
        generating_columns = {},  -- Columns currently being generated
        generated_columns = {},   -- Columns that have completed generation
    }
end

return WorldData
