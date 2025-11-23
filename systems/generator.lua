-- World Generation Module
-- Contains all terrain generation logic split into ordered steps

local noise = require "lib.noise"
local Registry = require "registries"

local BLOCKS = Registry.blocks()

local GeneratorSystem = {}

-- Constants
local SURFACE_HEIGHT_RATIO = 0.75
local BASE_FREQUENCY = 0.02
local BASE_AMPLITUDE = 15
local DIRT_MIN_DEPTH = 5
local DIRT_MAX_DEPTH = 15

-- Step 0: Calculate surface height using Perlin noise
local function calculate_surface_height(col, z, world_height)
    local noise_val = noise.octave_perlin2d(col * BASE_FREQUENCY, z * 0.1, 4, 0.5, 2.0)
    local base_height = math.floor(world_height * SURFACE_HEIGHT_RATIO + noise_val * BASE_AMPLITUDE)
    -- Layer-specific height adjustments
    if z == 1 then
        base_height = base_height + 5
    elseif z == -1 then
        base_height = base_height - 5
    end
    return base_height
end

-- Step 1: Fill terrain with air above surface and stone below
function GeneratorSystem.fill(layers, z, col, base_height, world_height)
    for row = 0, world_height - 1 do
        if row >= base_height then
            -- Underground - stone by default
            layers[z][col][row] = BLOCKS.STONE
        else
            -- Above ground - air
            layers[z][col][row] = BLOCKS.AIR
        end
    end
    layers[z][col][world_height - 2] = BLOCKS.BEDROCK
    layers[z][col][world_height - 1] = BLOCKS.BEDROCK
end

-- Step 2: Add dirt and grass
function GeneratorSystem.dirt_and_grass(layers, z, col, base_height, world_height)
    local dirt_depth = DIRT_MIN_DEPTH + math.floor((DIRT_MAX_DEPTH - DIRT_MIN_DEPTH) *
        (noise.perlin2d(col * 0.05, z * 0.1) + 1) / 2)
    for row = base_height, math.min(base_height + dirt_depth - 1, world_height - 1) do
        if layers[z][col][row] == BLOCKS.STONE then
            layers[z][col][row] = BLOCKS.DIRT
        end
    end
    if base_height > 0 and base_height < world_height then
        if layers[z][col][base_height] == BLOCKS.DIRT and
           layers[z][col][base_height - 1] == BLOCKS.AIR then
            layers[z][col][base_height] = BLOCKS.GRASS
        end
    end
end

-- Step 3: Generate ore veins using 3D Perlin noise
function GeneratorSystem.ore_veins(layers, z, col, base_height, world_height)
    for row = base_height, world_height - 3 do -- Stop before bedrock
        if layers[z][col][row] == BLOCKS.STONE then
            local depth_from_surface = row - base_height

            -- Coal: shallow, common (depth 5-100)
            if depth_from_surface >= 5 and depth_from_surface <= 100 then
                local coal_noise = noise.perlin3d(col * 0.08, row * 0.08, z * 0.08)
                if coal_noise > 0.5 then
                    layers[z][col][row] = BLOCKS.COAL
                end
            end

            -- Copper: shallow to mid (depth 10-120)
            if depth_from_surface >= 10 and depth_from_surface <= 120 then
                local copper_noise = noise.perlin3d(col * 0.07, row * 0.07, z * 0.07 + 100)
                if copper_noise > 0.55 then
                    layers[z][col][row] = BLOCKS.COPPER_ORE
                end
            end

            -- Tin: shallow to mid (depth 10-120)
            if depth_from_surface >= 10 and depth_from_surface <= 120 then
                local tin_noise = noise.perlin3d(col * 0.07, row * 0.07, z * 0.07 + 200)
                if tin_noise > 0.55 then
                    layers[z][col][row] = BLOCKS.TIN_ORE
                end
            end

            -- Iron: mid depth (depth 40-150)
            if depth_from_surface >= 40 and depth_from_surface <= 150 then
                local iron_noise = noise.perlin3d(col * 0.06, row * 0.06, z * 0.06 + 300)
                if iron_noise > 0.58 then
                    layers[z][col][row] = BLOCKS.IRON_ORE
                end
            end

            -- Lead: mid to deep (depth 50-160)
            if depth_from_surface >= 50 and depth_from_surface <= 160 then
                local lead_noise = noise.perlin3d(col * 0.06, row * 0.06, z * 0.06 + 400)
                if lead_noise > 0.6 then
                    layers[z][col][row] = BLOCKS.LEAD_ORE
                end
            end

            -- Zinc: mid to deep (depth 50-160)
            if depth_from_surface >= 50 and depth_from_surface <= 160 then
                local zinc_noise = noise.perlin3d(col * 0.06, row * 0.06, z * 0.06 + 500)
                if zinc_noise > 0.6 then
                    layers[z][col][row] = BLOCKS.ZINC_ORE
                end
            end

            -- Cobalt: deep and rare (depth 80+)
            if depth_from_surface >= 80 then
                local cobalt_noise = noise.perlin3d(col * 0.05, row * 0.05, z * 0.05 + 600)
                if cobalt_noise > 0.7 then -- Very rare threshold
                    layers[z][col][row] = BLOCKS.COBALT_ORE
                end
            end
        end
    end
end

-- Main terrain generation function that orchestrates all steps
function GeneratorSystem.generate_column(layers, z, col, world_height)
    -- Step 0: Calculate surface height
    local base_height = calculate_surface_height(col, z, world_height)
    -- Step 1: Fill base terrain (air and stone)
    GeneratorSystem.fill(layers, z, col, base_height, world_height)
    -- Step 2: Add dirt and grass layers
    GeneratorSystem.dirt_and_grass(layers, z, col, base_height, world_height)
    -- Step 3: Generate ore veins
    GeneratorSystem.ore_veins(layers, z, col, base_height, world_height)

end

return GeneratorSystem
