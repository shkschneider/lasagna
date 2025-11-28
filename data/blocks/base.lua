local BlockRef = require "data.blocks.ids"
local BlocksRegistry = require "registries.blocks"

-- Helper function to convert hex to rgb
local function hex2rgb(hex)
    local hex = hex:gsub("#", "")
    return tonumber("0x" .. hex:sub(1, 2)) / 255,
        tonumber("0x" .. hex:sub(3, 4)) / 255,
        tonumber("0x" .. hex:sub(5, 6)) / 255
end

-- Register Air
BlocksRegistry:register({
    id = BlockRef.AIR,
    name = "Air",
    solid = false,
    color = {0, 0, 0, 0},
    tier = 0,
})

-- Register Grass (bright green top layer)
BlocksRegistry:register({
    id = BlockRef.GRASS,
    name = "Grass",
    solid = true,
    color = {hex2rgb("#4a8c2e"), 1},  -- Fresh green
    tier = 0,
    drops = function() return BlockRef.DIRT, 1 end,
})

-- Register Dirt (brown soil)
BlocksRegistry:register({
    id = BlockRef.DIRT,
    name = "Dirt",
    solid = true,
    color = {hex2rgb("#8b5a2b"), 1},  -- Medium brown
    tier = 0,
    drops = function() return BlockRef.DIRT, 1 end,
})

-- Register Sand (light tan)
BlocksRegistry:register({
    id = BlockRef.SAND,
    name = "Sand",
    solid = true,
    color = {hex2rgb("#e6d4a3"), 1},  -- Sandy tan
    tier = 0,
    drops = function() return BlockRef.SAND, 1 end,
})

-- Register Stone (gray rock)
BlocksRegistry:register({
    id = BlockRef.STONE,
    name = "Stone",
    solid = true,
    color = {hex2rgb("#7a7a7a"), 1},  -- Medium gray
    tier = 1,
    drops = function() return BlockRef.STONE, 1 end,
})

-- Register Gravel (mixed gray pebbles)
BlocksRegistry:register({
    id = BlockRef.GRAVEL,
    name = "Gravel",
    solid = true,
    color = {hex2rgb("#9e9e9e"), 1},  -- Light gray with slight variation
    tier = 0,
    drops = function() return BlockRef.GRAVEL, 1 end,
})

-- Register Mud (dark wet brown)
BlocksRegistry:register({
    id = BlockRef.MUD,
    name = "Mud",
    solid = true,
    color = {hex2rgb("#5c4033"), 1},  -- Dark brown
    tier = 0,
    drops = function() return BlockRef.MUD, 1 end,
})

-- Register Basalt (dark volcanic rock)
BlocksRegistry:register({
    id = BlockRef.BASALT,
    name = "Basalt",
    solid = true,
    color = {hex2rgb("#3d3d3d"), 1},  -- Dark gray/black
    tier = 1,
    drops = function() return BlockRef.BASALT, 1 end,
})

-- Register Granite (pink-gray speckled)
BlocksRegistry:register({
    id = BlockRef.GRANITE,
    name = "Granite",
    solid = true,
    color = {hex2rgb("#a08070"), 1},  -- Pink-gray
    tier = 1,
    drops = function() return BlockRef.GRANITE, 1 end,
})

-- Register Limestone (light cream/beige)
BlocksRegistry:register({
    id = BlockRef.LIMESTONE,
    name = "Limestone",
    solid = true,
    color = {hex2rgb("#d4c9a8"), 1},  -- Cream/beige
    tier = 1,
    drops = function() return BlockRef.LIMESTONE, 1 end,
})

-- Register Sandstone (orange-tan layered)
BlocksRegistry:register({
    id = BlockRef.SANDSTONE,
    name = "Sandstone",
    solid = true,
    color = {hex2rgb("#c9a86c"), 1},  -- Orange-tan
    tier = 1,
    drops = function() return BlockRef.SANDSTONE, 1 end,
})

-- Register Slate (dark blue-gray)
BlocksRegistry:register({
    id = BlockRef.SLATE,
    name = "Slate",
    solid = true,
    color = {hex2rgb("#4a5568"), 1},  -- Blue-gray
    tier = 1,
    drops = function() return BlockRef.SLATE, 1 end,
})

-- Register Clay (orange-brown)
BlocksRegistry:register({
    id = BlockRef.CLAY,
    name = "Clay",
    solid = true,
    color = {hex2rgb("#b87333"), 1},  -- Terracotta orange
    tier = 0,
    drops = function() return BlockRef.CLAY, 1 end,
})

-- Register Wood
BlocksRegistry:register({
    id = BlockRef.WOOD,
    name = "Wood",
    solid = true,
    color = {hex2rgb("#8b6914"), 1},  -- Wood brown
    tier = 0,
    drops = function() return BlockRef.WOOD, 1 end,
})

-- Register Bedrock (unbreakable)
BlocksRegistry:register({
    id = BlockRef.BEDROCK,
    name = "Bedrock",
    solid = true,
    color = {hex2rgb("#1a1a1a"), 1},  -- Very dark gray
    tier = math.huge, -- Effectively unbreakable
    drops = function() return nil, 0 end, -- No drops
})
