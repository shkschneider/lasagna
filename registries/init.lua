-- Load default block definitions
local BLOCKS = require "data.blocks"
local ITEMS = require "data.items"

local Registry = {
    Blocks = require("registries.blocks"),
    Items = require("registries.items"),
}

-- Block registry interface
function Registry.block(id)
    return Registry.Blocks:get(id)
end

function Registry.blocks()
    return BLOCKS
end

-- Item registry interface
function Registry.item(id)
    return Registry.Items:get(id)
end

function Registry.items()
    return ITEMS
end

return Registry
