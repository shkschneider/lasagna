-- Recipes for the workbench
-- Each recipe has:
--   inputs: table of { block_id = count } pairs
--   output: { block_id = block_id, count = count }

local BlockRef = require "data.blocks.ids"

local recipes = {}

-- Recipe: 4 Wood -> 1 Wood (placeholder example)
-- This is just a proof of concept for the machine system
table.insert(recipes, {
    inputs = {
        [BlockRef.WOOD] = 4,
    },
    output = {
        block_id = BlockRef.WOOD,
        count = 1,
    },
})

-- Recipe: 2 Stone -> 1 Stone (another placeholder example)
table.insert(recipes, {
    inputs = {
        [BlockRef.STONE] = 2,
    },
    output = {
        block_id = BlockRef.STONE,
        count = 1,
    },
})

return recipes
