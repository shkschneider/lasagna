-- WorldData component
-- World dimensions and storage
-- World is infinite horizontally using chunks of 64 columns each

local WorldData = {}

function WorldData.new(seed, height)
    return {
        id = "worlddata",
        seed = seed or math.floor(love.math.random() * INFINITY),
        height = height or 512,
        -- Chunk-based storage: layers[z][chunk_index] contains 64 columns
        -- No horizontal width limit - chunks are generated on demand
        chunks = {
            [-1] = {},
            [0] = {},
            [1] = {},
        },
        generating_chunks = {},  -- Chunks currently being generated
        generated_chunks = {},   -- Chunks that have completed generation
    }
end

return WorldData
