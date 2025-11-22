local BlocksRegistry = require("registries.blocks")
local ItemsRegistry = require("registries.items")

-- Load default block definitions
local BLOCK_IDS = require("data.blocks")

local Registry = {}

-- Block registry interface
function Registry.block(id)
    return BlocksRegistry:get(id)
end

function Registry.blocks()
    return BlocksRegistry
end

function Registry.block_ids()
    return BLOCK_IDS
end

-- Item registry interface
function Registry.item(id)
    return ItemsRegistry:get(id)
end

function Registry.items()
    return ItemsRegistry
end

return Registry
