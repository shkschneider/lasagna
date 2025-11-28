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
    color = {hex2rgb("#4a8c2e")},  -- Fresh green
    tier = 0,
    drops = function() return BlockRef.DIRT end,
})

-- Register Dirt (brown soil)
BlocksRegistry:register({
    id = BlockRef.DIRT,
    name = "Dirt",
    solid = true,
    color = {hex2rgb("#8b5a2b")},  -- Medium brown
    tier = 0,
    drops = function() return BlockRef.DIRT end,
})

-- Register Sand (light tan)
BlocksRegistry:register({
    id = BlockRef.SAND,
    name = "Sand",
    solid = true,
    color = {hex2rgb("#e6d4a3")},  -- Sandy tan
    tier = 0,
    drops = function() return BlockRef.SAND end,
})

-- Register Stone (gray rock)
BlocksRegistry:register({
    id = BlockRef.STONE,
    name = "Stone",
    solid = true,
    color = {hex2rgb("#7a7a7a")},  -- Medium gray
    tier = 1,
    drops = function() return BlockRef.STONE end,
})

-- Register Gravel (mixed gray pebbles)
BlocksRegistry:register({
    id = BlockRef.GRAVEL,
    name = "Gravel",
    solid = true,
    color = {hex2rgb("#9e9e9e")},  -- Light gray with slight variation
    tier = 0,
    drops = function() return BlockRef.GRAVEL end,
})

-- Register Mud (dark wet brown)
BlocksRegistry:register({
    id = BlockRef.MUD,
    name = "Mud",
    solid = true,
    color = {hex2rgb("#5c4033")},  -- Dark brown
    tier = 0,
    drops = function() return BlockRef.MUD end,
})

-- Register Basalt (dark volcanic rock)
BlocksRegistry:register({
    id = BlockRef.BASALT,
    name = "Basalt",
    solid = true,
    color = {hex2rgb("#3d3d3d")},  -- Dark gray/black
    tier = 1,
    drops = function() return BlockRef.BASALT end,
})

-- Register Granite (pink-gray speckled)
BlocksRegistry:register({
    id = BlockRef.GRANITE,
    name = "Granite",
    solid = true,
    color = {hex2rgb("#a08070")},  -- Pink-gray
    tier = 1,
    drops = function() return BlockRef.GRANITE end,
})

-- Register Limestone (light cream/beige)
BlocksRegistry:register({
    id = BlockRef.LIMESTONE,
    name = "Limestone",
    solid = true,
    color = {hex2rgb("#d4c9a8")},  -- Cream/beige
    tier = 1,
    drops = function() return BlockRef.LIMESTONE end,
})

-- Register Sandstone (orange-tan layered)
BlocksRegistry:register({
    id = BlockRef.SANDSTONE,
    name = "Sandstone",
    solid = true,
    color = {hex2rgb("#c9a86c")},  -- Orange-tan
    tier = 1,
    drops = function() return BlockRef.SANDSTONE end,
})

-- Register Slate (dark blue-gray)
BlocksRegistry:register({
    id = BlockRef.SLATE,
    name = "Slate",
    solid = true,
    color = {hex2rgb("#4a5568")},  -- Blue-gray
    tier = 1,
    drops = function() return BlockRef.SLATE end,
})

-- Register Clay (orange-brown)
BlocksRegistry:register({
    id = BlockRef.CLAY,
    name = "Clay",
    solid = true,
    color = {hex2rgb("#b87333")},  -- Terracotta orange
    tier = 0,
    drops = function() return BlockRef.CLAY end,
})

-- Register Wood
BlocksRegistry:register({
    id = BlockRef.WOOD,
    name = "Wood",
    solid = true,
    color = {hex2rgb("#8b6914")},  -- Wood brown
    tier = 0,
    drops = function() return BlockRef.WOOD end,
})

-- Register Bedrock (unbreakable)
BlocksRegistry:register({
    id = BlockRef.BEDROCK,
    name = "Bedrock",
    solid = true,
    color = {hex2rgb("#1a1a1a")},  -- Very dark gray
    tier = math.huge, -- Effectively unbreakable
    drops = function() return nil, 0 end, -- No drops
})
