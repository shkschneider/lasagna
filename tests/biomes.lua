-- tests/biomes.lua
-- CLI tests for data/world/biomes registration and validation.
-- Run from repo root:
--   lua ./tests/biomes.lua

local function ok(msg)
    print("PASS: " .. msg)
end
local function fail(msg)
    print("FAIL: " .. msg)
    os.exit(1)
end
local function expect(cond, msg)
    if cond then ok(msg) else fail(msg) end
end

-- Setup minimal mocks for LÖVE environment
love = {
    filesystem = {
        getInfo = function() return nil end,
    },
}

-- Global constants used by the game
BLOCK_SIZE = 16
G = {}

-- Mock the core.object module
package.loaded["core.object"] = function(tbl) return tbl end

-- Load the biomes registry and biome data
print("-- Loading BiomesRegistry...")
local BiomesRegistry = require("src.registries.biomes")

print("-- Loading biome data files...")
require("data.world.biomes")

-- Test 1: Check that biomes were registered
print("\n-- Test 1: Biomes registered correctly")
local biome_count = BiomesRegistry:count()
expect(biome_count == 10, "Expected 10 biomes, got " .. tostring(biome_count))

-- Test 2: Check all expected biomes exist by name
print("\n-- Test 2: All expected biomes exist by name")
local expected_biomes = {
    "Tundra", "Taiga", "Snowy Hills",
    "Forest", "Plains",
    "Jungle", "Swamp",
    "Savanna", "Badlands", "Desert"
}
for _, name in ipairs(expected_biomes) do
    expect(BiomesRegistry:exists(name), "Biome '" .. name .. "' exists")
end

-- Test 3: Check all biomes have required fields
print("\n-- Test 3: All biomes have required fields")
local required_fields = {"id", "name", "temperature", "humidity", "surface", "subsurface"}
for id, biome in BiomesRegistry:iterate() do
    for _, field in ipairs(required_fields) do
        expect(biome[field] ~= nil, "Biome " .. biome.name .. " has field '" .. field .. "'")
    end
end

-- Test 4: Check biome IDs are sequential 1-10
print("\n-- Test 4: Biome IDs are sequential 1-10")
for i = 1, 10 do
    local biome = BiomesRegistry:get(i)
    expect(biome ~= nil, "Biome with ID " .. i .. " exists")
    expect(biome.id == i, "Biome ID " .. i .. " matches expected")
end

-- Test 5: Check temperature values are valid
print("\n-- Test 5: Temperature values are valid")
local valid_temperatures = {
    ["freezing"] = true,
    ["cold"] = true,
    ["normal"] = true,
    ["warm"] = true,
    ["hot"] = true,
}
for id, biome in BiomesRegistry:iterate() do
    expect(valid_temperatures[biome.temperature],
        "Biome " .. biome.name .. " has valid temperature '" .. tostring(biome.temperature) .. "'")
end

-- Test 6: Check humidity values are valid
print("\n-- Test 6: Humidity values are valid")
local valid_humidities = {
    ["arid"] = true,
    ["dry"] = true,
    ["normal"] = true,
    ["wet"] = true,
    ["humid"] = true,
}
for id, biome in BiomesRegistry:iterate() do
    expect(valid_humidities[biome.humidity],
        "Biome " .. biome.name .. " has valid humidity '" .. tostring(biome.humidity) .. "'")
end

-- Test 7: Check surface and subsurface are valid block IDs
print("\n-- Test 7: Surface and subsurface are valid block IDs")
for id, biome in BiomesRegistry:iterate() do
    expect(type(biome.surface) == "number", "Biome " .. biome.name .. " surface is a number")
    expect(type(biome.subsurface) == "number", "Biome " .. biome.name .. " subsurface is a number")
    expect(biome.surface > 0, "Biome " .. biome.name .. " surface is positive")
    expect(biome.subsurface > 0, "Biome " .. biome.name .. " subsurface is positive")
end

-- Test 8: Check biome helper functions work
print("\n-- Test 8: Biome helper functions work")
local Biome = require("src.world.biome")

-- Test get_by_id
local plains = Biome.get_by_id(5)
expect(plains ~= nil, "get_by_id(5) returns a biome")
expect(plains.name == "Plains", "get_by_id(5) returns Plains")

-- Test get_by_climate (cold+dry should return ids 1-3)
local cold_dry = Biome.get_by_climate(0.2, 0.2)
expect(cold_dry ~= nil, "get_by_climate(0.2, 0.2) returns a biome")
expect(cold_dry.id >= 1 and cold_dry.id <= 3, "Cold+Dry climate returns biome ID 1-3")

-- Test get_by_climate (hot+wet should return ids 6-7)
local hot_wet = Biome.get_by_climate(0.7, 0.7)
expect(hot_wet ~= nil, "get_by_climate(0.7, 0.7) returns a biome")
expect(hot_wet.id >= 6 and hot_wet.id <= 7, "Hot+Wet climate returns biome ID 6-7")

-- Test get_surface_block
local surface_block = Biome.get_surface_block(plains)
expect(surface_block ~= nil, "get_surface_block returns a value")
expect(type(surface_block) == "number", "get_surface_block returns a number")

-- Test get_subsurface_block
local subsurface_block = Biome.get_subsurface_block(plains)
expect(subsurface_block ~= nil, "get_subsurface_block returns a value")
expect(type(subsurface_block) == "number", "get_subsurface_block returns a number")

print("\n=== All biome tests passed! ===")
