local Colors = require "libs.colors"
local BlockRef = require "data.blocks.ids"
local BlocksRegistry = require "src.registries.blocks"

-- Register Workbench (crafting machine)
BlocksRegistry:register({
    id = BlockRef.WORKBENCH,
    name = "Workbench",
    solid = true,
    color = Colors.brown.light,  -- Light brown to distinguish from wood
    tier = 0,
    drops = function() return BlockRef.WORKBENCH end,
})
