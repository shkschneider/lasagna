-- Recipes for the workbench
-- Each recipe has:
--   inputs: table of { [block_id] = count } pairs
--   output: table of { [block_id] = count } pairs

local BlockRef = require "data.blocks.ids"

local recipes = {}

-- Recipe: 1 Stone -> 4 Gravel
table.insert(recipes, {
    inputs = {
        [BlockRef.STONE] = 1,
    },
    output = {
        [BlockRef.GRAVEL] = 4,
    },
})

return recipes
