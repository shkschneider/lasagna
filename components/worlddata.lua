-- WorldData component
-- World dimensions and storage

local WorldData = {}

function WorldData.new(seed, width, height)
    return {
        id = "worlddata",
        seed = seed or math.floor(love.math.random() * INFINITY),
        width = width or 512,
        height = height or 128,
        layers = {
            [-1] = {},
            [0] = {},
            [1] = {},
        },
        generated_columns = {},
    }
end

return WorldData
