# Verification Testing for Ore Generation Refactoring

## Testing Approach

Since the repository doesn't have automated tests, manual verification is recommended when testing the ore generation changes.

## Manual Verification Steps

### 1. Start the Game
```bash
love .
```

### 2. Visual Verification
- Explore underground in the game
- Verify that all 7 ore types are present:
  - Coal (black/dark gray) - should appear at shallow depths (5-100 blocks)
  - Copper Ore (orange/brown) - shallow to mid depths (10-120 blocks)
  - Tin Ore (light gray) - shallow to mid depths (10-120 blocks)
  - Iron Ore (brownish gray) - mid depths (40-150 blocks)
  - Lead Ore (blue-gray) - mid to deep (50-160 blocks)
  - Zinc Ore (light blue-gray) - mid to deep (50-160 blocks)
  - Cobalt Ore (blue) - deep and rare (80+ blocks)

### 3. Ore Distribution Verification
- Coal should be common and appear early when digging
- Copper and Tin should be moderately common at shallow-mid depths
- Iron, Lead, and Zinc should appear less frequently at greater depths
- Cobalt should be rare and only appear at significant depths

### 4. Verify No Regressions
- World generation should complete without errors
- No console errors related to ore generation
- Game performance should be unchanged
- Saving and loading worlds should work normally

## Testing with Different Seeds

To test that ore generation is consistent and deterministic:

```bash
# Test with specific seed
SEED=12345 love .
```

Exit and restart with the same seed to verify ore placement is identical.

## Expected Behavior

After the refactoring:
- All ore types should generate exactly as before
- No visual differences in ore distribution
- Same performance characteristics
- World generation should be deterministic (same seed = same ores)

## What Changed Internally

The refactoring changed **how** ores are generated (data-driven vs hardcoded) but **not what** is generated. The ore generation parameters were copied exactly from the previous hardcoded values:

| Ore | Min Depth | Max Depth | Frequency | Threshold | Offset |
|-----|-----------|-----------|-----------|-----------|--------|
| Coal | 5 | 100 | 0.08 | 0.5 | 0 |
| Copper | 10 | 120 | 0.07 | 0.55 | 100 |
| Tin | 10 | 120 | 0.07 | 0.55 | 200 |
| Iron | 40 | 150 | 0.06 | 0.58 | 300 |
| Lead | 50 | 160 | 0.06 | 0.6 | 400 |
| Zinc | 50 | 160 | 0.06 | 0.6 | 500 |
| Cobalt | 80 | 999 | 0.05 | 0.7 | 600 |

## Regression Testing Checklist

- [ ] Game starts without errors
- [ ] Can create a new world
- [ ] All 7 ore types are visible when exploring underground
- [ ] Ore distribution matches expectations (common → rare based on depth)
- [ ] No performance degradation
- [ ] Can mine and collect all ore types
- [ ] World generation is deterministic with fixed seeds
- [ ] No console errors during world generation

## Future Testing Recommendations

When adding a new ore using the modularized system:

1. Add the ore to `data/blocks.lua` with `ore_gen` metadata
2. Start the game and generate a new world
3. Use the `/tp` command (if available) or dig down to the ore's depth range
4. Verify the ore spawns at the expected depth and frequency
5. Verify the ore can be mined and collected
6. Test with multiple seeds to ensure consistent generation
