-- WorldData Component
-- Stores world data and generation parameters

local WorldData = {}

function WorldData.new(seed, height)
    return {
        seed = seed,
        height = height or 512,
        columns = {},  -- Sparse table for column data
    }
end

return WorldData
