# Testing Guide for Age-Gated Crafting System

## Manual Testing Checklist

### Prerequisites
- LÖVE 2D framework installed
- Game running with `love .`

### Test 1: Initial State
1. Start a new game
2. Open inventory (press E or I)
3. Verify:
   - [ ] Crafting UI appears on the right side of the inventory
   - [ ] Shows "Current: Stone Age" (Age 0)
   - [ ] Shows "Next: Bronze Age" (Age 1)
   - [ ] Shows required materials: "Copper Ore: 0/9" in red
   - [ ] Craft button shows "NOT ENOUGH MATERIALS" and is grayed out

### Test 2: Collecting Materials
1. Mine and collect copper ore blocks
2. Verify:
   - [ ] Material count updates in crafting UI
   - [ ] Color changes from red to green when reaching 9/9
   - [ ] Craft button changes to "UPGRADE AGE" and becomes clickable

### Test 3: Age Upgrade (Bronze Age)
1. With 9 copper ore, click "UPGRADE AGE"
2. Verify:
   - [ ] Copper ore is consumed from inventory
   - [ ] Omnitool tier increases from 0 to 1
   - [ ] Tier progress bar updates
   - [ ] Crafting UI now shows:
     - Current: Bronze Age
     - Next: Iron Age
     - Required: Iron Ore: 0/9

### Test 4: Age Upgrade (Iron Age)
1. Collect 9 iron ore
2. Click "UPGRADE AGE"
3. Verify:
   - [ ] Iron ore is consumed
   - [ ] Tier increases to 2
   - [ ] UI shows Steel Age as next

### Test 5: Age Upgrade (Steel Age)
1. Collect 9 coal
2. Click "UPGRADE AGE"
3. Verify:
   - [ ] Coal is consumed
   - [ ] Tier increases to 3
   - [ ] UI shows Flux Age as next

### Test 6: Maximum Age
1. At Steel Age (tier 3)
2. Verify:
   - [ ] Crafting UI shows "Max Age Reached!" or similar
   - [ ] No recipe requirements shown
   - [ ] Craft button is disabled (Flux Age recipe is disabled)

### Test 7: Material Counting
1. Split materials between hotbar and backpack
2. Verify:
   - [ ] Both inventories are counted toward requirements
   - [ ] Materials are consumed from both locations

### Test 8: Performance
1. Open inventory and observe crafting UI
2. Verify:
   - [ ] UI remains responsive
   - [ ] No visible lag when checking requirements
   - [ ] Material counts update smoothly (every 1 second due to tick system)

### Test 9: Edge Cases
1. Try clicking craft button when requirements not met
   - [ ] Nothing happens, materials not consumed
2. Try upgrading with materials split across inventories
   - [ ] Works correctly
3. Try with exactly 9 materials
   - [ ] Upgrade works, all consumed

## Automated Tests

### Tick System
Run: `lua5.1 tests/tick.lua`

Expected output:
```
[PASS] Create a tick
[PASS] Tick doesn't fire before threshold
[PASS] Tick fires at threshold
[PASS] Tick fires multiple times
[PASS] Reset works
[PASS] Progress tracking
[PASS] Invalid parameters
----------------------------------------
Results: 7 passed, 0 failed
----------------------------------------
```

## Known Limitations

1. Flux Age (tier 4) is intentionally disabled
2. Old UPGRADE button (for debugging) still works alongside new system
3. Material recipes are placeholder (bronze uses copper ore instead of actual bronze bars)

## Debug Commands

While testing, you can use debug mode:
```bash
DEBUG=true love .
```

This enables:
- Debug upgrade button (bypasses material requirements)
- Additional logging
- Extra debug info on screen

## Future Improvements

- Add actual crafting recipes (not just age upgrades)
- Add intermediate materials (bronze bars, steel ingots, etc.)
- Add crafting animations/feedback
- Add sound effects for successful upgrades
- Add tooltips showing recipe details
