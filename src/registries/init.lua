local here = (...):gsub("%.init$", "") .. "."

local Registry = {
    Blocks = require(here .. "blocks"),
    Items = require(here .. "items"),
    Commands = require(here .. "commands"),
    Biomes = require(here .. "biomes"),
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

-- Biomes

local BIOMES = require "data.world.biomes"

function Registry.biome(id_or_name)
    return Registry.Biomes:get(id_or_name)
end

function Registry.biomes()
    return BIOMES
end

return Registry
