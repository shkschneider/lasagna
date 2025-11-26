local Registry = {
    Blocks = require("registries.blocks"),
    Items = require("registries.items"),
    Commands = require("registries.commands"),
    World = require("registries.world"),
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

-- Commands

local COMMANDS = require "data.commands"

function Registry.command(name)
    return Registry.Commands:get(name)
end

function Registry.commands()
    return COMMANDS
end

return Registry
