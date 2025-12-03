local WorldSeed = {
    id = "worlddata",
    HEIGHT = 512,
    tostring = function(self)
        return tostring(self.seed)
    end,
}

function WorldSeed.new(seed, height)
    assert(seed)
    local worlddata = {
        seed = seed,
        height = height or WorldSeed.HEIGHT,
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
    return setmetatable(worlddata, { __index = WorldSeed })
end

return WorldSeed
