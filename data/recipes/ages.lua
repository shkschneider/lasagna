-- Age Upgrade Recipes
-- Recipes for upgrading the omnitool to the next tier/age
-- Each age requires collecting specific materials

local BlockRef = require "data.blocks.ids"

-- Recipe structure:
-- {
--   age = <target_age>,
--   inputs = { {id = <block/item_id>, type = "block"|"item", count = N}, ... },
--   outputs = {} -- Empty for age upgrades (just unlocks next tier)
-- }

return {
    -- Age 0 -> Age 1 (Bronze Age)
    -- Requires 9 copper ore (placeholder for bronze material)
    {
        age = 1,
        inputs = {
            { id = BlockRef.COPPER_ORE, type = "block", count = 9 },
        },
        outputs = {}, -- No outputs, just upgrades the omnitool
    },
    
    -- Age 1 -> Age 2 (Iron Age)
    -- Requires 9 iron ore
    {
        age = 2,
        inputs = {
            { id = BlockRef.IRON_ORE, type = "block", count = 9 },
        },
        outputs = {},
    },
    
    -- Age 2 -> Age 3 (Steel Age)
    -- Requires 9 coal (for steel production)
    {
        age = 3,
        inputs = {
            { id = BlockRef.COAL, type = "block", count = 9 },
        },
        outputs = {},
    },
    
    -- Age 3 -> Age 4 (Flux Age)
    -- Disabled for now (will require cobalt ore when enabled)
    -- {
    --     age = 4,
    --     inputs = {
    --         { id = BlockRef.COBALT_ORE, type = "block", count = 9 },
    --     },
    --     outputs = {},
    -- },
}
