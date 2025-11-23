# Adding New Ores

The GeneratorSystem has been modularized to make adding new ores simple and scalable. Instead of modifying the generator code directly, you can now add ores by registering them with ore generation metadata.

## How to Add a New Ore

To add a new ore, you only need to modify `data/blocks.lua`:

### Step 1: Add the ore ID to BlockRef

```lua
local BlockRef = {
    -- ... existing blocks ...
    MY_NEW_ORE = 14,  -- Choose the next available ID
}
```

### Step 2: Register the ore block with ore_gen metadata

```lua
-- Register My New Ore
BlocksRegistry:register({
    id = BlockRef.MY_NEW_ORE,
    name = "My New Ore",
    solid = true,
    color = {0.9, 0.1, 0.5, 1},  -- Pink color (RGBA)
    tier = 3,  -- Tool tier required to mine
    drops = function() return BlockRef.MY_NEW_ORE, 1 end,
    ore_gen = {
        min_depth = 60,      -- Minimum depth from surface to spawn
        max_depth = 200,     -- Maximum depth from surface to spawn
        frequency = 0.05,    -- Noise frequency (lower = larger veins)
        threshold = 0.65,    -- Noise threshold (higher = rarer)
        offset = 700,        -- Noise offset to differentiate from other ores
    },
})
```

That's it! The GeneratorSystem will automatically pick up your new ore and generate it during world generation.

## Ore Generation Parameters

### min_depth
- Minimum depth below the surface where the ore can spawn
- Lower values = spawns closer to surface
- Example: `5` for shallow ores like coal

### max_depth
- Maximum depth below the surface where the ore can spawn
- Higher values = spawns deeper underground
- Use `math.huge` for ores that spawn at any depth below min_depth (unbounded)
- Example: `100` for shallow ores, `math.huge` for deep ores like cobalt

### frequency
- Controls the size of ore veins
- Lower values = larger, smoother veins
- Higher values = smaller, more scattered deposits
- Typical range: `0.05` to `0.08`

### threshold
- Controls ore rarity
- Higher values = rarer ore
- Lower values = more common ore
- Typical range: `0.5` (common) to `0.7` (rare)

### offset
- Noise offset to ensure different ores use different noise patterns
- Should be unique for each ore type
- Increment by 100 for each new ore
- Example: If the last ore uses `600`, use `700` for the next

## Examples

### Common Shallow Ore (like Coal)
```lua
ore_gen = {
    min_depth = 5,
    max_depth = 100,
    frequency = 0.08,
    threshold = 0.5,
    offset = 0,
}
```

### Mid-Depth Uncommon Ore (like Iron)
```lua
ore_gen = {
    min_depth = 40,
    max_depth = 150,
    frequency = 0.06,
    threshold = 0.58,
    offset = 300,
}
```

### Deep Rare Ore (like Cobalt)
```lua
ore_gen = {
    min_depth = 80,
    max_depth = math.huge,  -- Unbounded depth
    frequency = 0.05,
    threshold = 0.7,
    offset = 600,
}
```

## Technical Details

The ore generation system works as follows:

1. When a world column is generated, the GeneratorSystem calls `ore_veins()`
2. `ore_veins()` queries the BlocksRegistry for all blocks with `ore_gen` metadata
3. Ore blocks are sorted by ID for deterministic ordering
4. For each stone block underground, it iterates through registered ores
5. If a position is within an ore's depth range, it generates 3D Perlin noise
6. If the noise value exceeds the threshold, the ore is placed
7. The loop continues checking other ores (later ores can override earlier ones)

This approach makes the system:
- **Scalable**: Add ores without touching generator code
- **Maintainable**: All ore properties in one place
- **Flexible**: Easy to adjust ore distribution
- **Data-driven**: Ore generation driven by block metadata
