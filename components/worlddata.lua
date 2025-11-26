-- WorldData component
-- World dimensions and storage
-- World is infinite horizontally with column-based storage and generation

local WorldDataComponent = {
    HEIGHT = 512,
}

function WorldDataComponent.new(seed, height)
    local worlddata = {
        id = "worlddata",
        seed = seed or math.random(),
        height = height or WorldDataComponent.HEIGHT,
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
    return setmetatable(worlddata, { __index = WorldDataComponent })
end

return WorldDataComponent
