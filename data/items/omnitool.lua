-- Omnitool item definition

local ItemRef = require "data.items.ids"
local ItemsRegistry = require "src.registries.items"

-- Register Omnitool
ItemsRegistry:register({
    id = ItemRef.OMNITOOL,
    name = "Omnitool",
    color = {1, 1, 1, 1}, -- White
    -- No durability (unbreakable)
    -- No weapon stats (not a weapon)
})
