-- WorldData component
-- World dimensions and storage
-- World is infinite horizontally with column-based storage and generation

local WorldDataComponent = {}

function WorldDataComponent.new(seed, height)
    return {
        id = "worlddata",
        seed = seed or math.floor(love.math.random() * math.inf),
        height = height or 512,
        -- Column-based storage: columns[z][col] contains rows
        -- No horizontal width limit - columns are generated on demand
        columns = {
            [-1] = {},
            [0] = {},
            [1] = {},
        },
        generating_columns = {},  -- Columns currently being generated
        generated_columns = {},   -- Columns that have completed generation
        -- Block changes: tracks modifications from procedurally generated terrain
        -- Format: changes[z][col][row] = block_id (nil means no change from generated)
        changes = {
            [-1] = {},
            [0] = {},
            [1] = {},
        },
    }
end

return WorldDataComponent
