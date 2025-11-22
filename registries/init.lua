local Registry = {
    Blocks = require("registries.blocks"),
    Items = require("registries.items"),
}

-- Blocks

local BLOCKS = require "data.blocks"

function Registry.block(id)
    return Registry.Blocks:get(id)
end

function Registry.blocks()
    return BLOCKS
end

-- Items

local ITEMS = require "data.items"

function Registry.item(id)
    return Registry.Items:get(id)
end

function Registry.items()
    return ITEMS
end

return Registry
