# Machine System Documentation

## Overview

The machine system provides a framework for placing interactive, in-world machines that process items. The first machine implemented is the **Workbench**, which performs crafting by checking for ItemDrops placed on top of it.

## Architecture

### Base Machine (`src/machines/init.lua`)

The base `Machine` object provides common functionality for all machines:

- **Position**: Machines are stationary entities placed at specific world coordinates
- **Entity Properties**: Machines are entities with `type = "machine"` and `priority = 40`
- **No Movement**: Machines have zero velocity and gravity
- **Rendering**: Base draw method renders the machine as a colored block

Key properties:
```lua
{
    id = <unique_id>,
    type = "machine",
    priority = 40,
    position = Vector.new(x, y, layer),
    velocity = Vector.new(0, 0),
    gravity = 0,
    block_id = <block_type>,
    dead = false,
}
```

### Workbench Machine (`src/machines/workbench.lua`)

The Workbench extends the base Machine to provide crafting functionality:

1. **Item Detection**: Checks for ItemDrops on top of the workbench (within BLOCK_SIZE range)
2. **Recipe Matching**: Compares items on top with registered recipes
3. **Crafting**: Consumes input items and spawns output items at the bottom

#### How It Works

**Detection Range**: The workbench looks for ItemDrops that are:
- On the same layer (`z` coordinate)
- Horizontally aligned (within BLOCK_SIZE width)
- Above the workbench (within BLOCK_SIZE height above)

**Recipe Matching**: 
- Counts items by `block_id`
- Requires exact match (no extra items, exact counts)
- Processes first matching recipe found

**Output Spawning**:
- Input ItemDrops are marked as `dead` (consumed)
- Output ItemDrop spawns at bottom center of workbench
- Output has standard lifetime and pickup delay

### Recipe System (`data/recipes/workbench.lua`)

Recipes are simple tables defining inputs and outputs:

```lua
{
    inputs = {
        [block_id] = count,
        ...
    },
    output = {
        block_id = block_id,
        count = count,
    },
}
```

**Current Placeholder Recipes**:
- 4 Wood → 1 Wood
- 2 Stone → 1 Stone

These are intentionally simple for prototyping. Real recipes should be added later.

## Integration

### Block Registration (`data/blocks/machines.lua`)

The WORKBENCH block is registered like any other block:
- Block ID: 24
- Solid: true
- Color: light brown
- Tier: 0 (placeable with starter tool)
- Drops itself when mined

### Building System (`src/world/building.lua`)

When a WORKBENCH block is placed:
1. Block is placed in world grid
2. `spawn_machine_entity()` is called
3. Workbench entity is created and added to entities system
4. Workbench begins updating every frame

### Mining System (`src/world/mining.lua`)

When a WORKBENCH block is mined:
1. Block is removed from world grid
2. `remove_machine_entity()` is called
3. Machine entity at that position is marked as `dead`
4. Entity system removes it on next cleanup
5. ItemDrop is spawned as usual

## Usage

### For Players

1. **Place a Workbench**: Right-click with WORKBENCH block selected in hotbar
2. **Add Items**: Drop items (mine and drop blocks) onto the top of the workbench
3. **Crafting**: When items match a recipe, they're consumed and output appears at bottom
4. **Collect Output**: Pick up the output ItemDrop from below the workbench
5. **Remove Workbench**: Mine it to get the block back

### For Developers

**Adding a New Machine Type**:

1. Create `src/machines/<machine_name>.lua`
2. Extend the base Machine
3. Override `update()` method with custom logic
4. Add block to `data/blocks/ids.lua`
5. Register block in `data/blocks/machines.lua`
6. Update `spawn_machine_entity()` and `remove_machine_entity()` in building/mining systems

**Adding Recipes**:

Edit `data/recipes/workbench.lua` to add new recipes following the structure above.

## Design Philosophy

### In-World Crafting

The machine system implements **in-world crafting** rather than a traditional GUI-based crafting table. This design:

- **Encourages Exploration**: Players must physically place machines in the world
- **Visible Process**: Crafting is visible as items sit on machines
- **Spatial Gameplay**: Machine placement matters (proximity to resources, organization)
- **Multiplayer Ready**: Multiple players could potentially use the same machine
- **Physical Limitations**: Storage and organization are part of the challenge

### Why No GUI?

Traditional Minecraft-style crafting grids require:
- Opening interfaces that pause gameplay
- Remembering recipes or consulting external guides
- Abstract item placement in grids

In-world crafting offers:
- Continuous gameplay without menu breaks
- Visual recipe discovery (see what works)
- Physical interaction with the game world
- Potential for automation and logistics systems

## Ideas for Improvement

### Short-term (Prototype Extensions)

1. **Visual Feedback**:
   - Add particle effects when crafting completes
   - Show progress indicator while items are being processed
   - Highlight machine when player is nearby with matching items

2. **Better Recipes**:
   - Replace placeholder recipes with useful ones
   - Add progression: Wood Planks, Stone Tools, etc.
   - Make recipes teach the Age progression system

3. **Recipe Discovery**:
   - Add visual hints (icons/symbols on machine)
   - Show recipe book UI (non-blocking, reference only)
   - Add recipe unlock system tied to Age progression

4. **Multi-slot Input**:
   - Allow multiple different items on top (current system supports this)
   - Recipes requiring 2-3 different block types
   - Position-based recipes (left/center/right slots)

### Medium-term (Gameplay Expansion)

5. **Machine Varieties**:
   - **Furnace**: Smelts ores into ingots (requires fuel)
   - **Crusher**: Converts blocks into smaller materials
   - **Assembler**: Combines materials into complex items
   - **Enchanter**: Upgrades tools/weapons

6. **Processing Time**:
   - Add crafting duration to recipes
   - Show progress bar or animation
   - Balance fast vs. slow crafting for different items

7. **Power/Fuel System**:
   - Some machines require fuel (coal, etc.)
   - Visual fuel meter on machine
   - Machines shutdown when out of fuel

8. **Machine Upgrades**:
   - Tier 1/2/3 versions of machines
   - Faster processing, multiple outputs, new recipes
   - Craft better machines using old machines

### Long-term (Advanced Systems)

9. **Automation**:
   - **Conveyors**: Move items between machines automatically
   - **Hoppers**: Insert/extract items from machines
   - **Pipes**: Fluid/item transport networks
   - **Sorters**: Route items based on type

10. **Multiblock Structures**:
    - Large machines requiring multiple blocks
    - Blast furnaces, assembly lines, etc.
    - More powerful but require space and resources

11. **Machine Logic**:
    - Conditional recipes (if X then Y else Z)
    - Priority systems (process this first)
    - Batch crafting (craft N items at once)
    - Recipe chaining (output of A feeds into B)

12. **Specialized Workbenches**:
    - Weapon Bench: Craft/upgrade weapons
    - Armor Stand: Craft/enchant armor
    - Alchemy Station: Brew potions
    - Electronics Bench: Circuit crafting (higher ages)

### Quality of Life

13. **Smart Inventory**:
    - Auto-place items on machines from inventory
    - Quick-craft button (if ingredients in inventory)
    - Batch crafting queue

14. **Recipe Memory**:
    - Last-used recipe caching
    - "Craft again" shortcut
    - Recipe favorites/bookmarks

15. **Machine Interaction**:
    - Right-click to see machine status
    - Shows current items, progress, recipes available
    - "Ghost items" showing what's needed for recipes

## Technical Considerations

### Performance

- Machines update every frame but only check entity system
- Recipe matching is O(recipes × ingredients) - fine for small recipe sets
- Consider spatial partitioning if many machines exist
- ItemDrop detection uses simple AABB checks

### Multiplayer

The current system should work in multiplayer with minimal changes:
- Machines are entities visible to all players
- ItemDrops have layer requirements (prevents cross-layer interference)
- Recipe processing is deterministic (first match wins)
- Potential race condition: two players placing items simultaneously
  - Solution: Add processing delay or lock mechanism

### Save/Load

Currently machines are NOT persisted:
- Machines only exist while world is loaded
- Mining a machine drops the block (player can replace it)
- **TODO**: Add machine persistence to world save system
  - Store machine positions and states
  - Restore machines on world load
  - Track in-progress crafting operations

### Testing

The machine system includes comprehensive unit tests:
- Machine/Workbench creation
- Item detection (on top, range, layer)
- Item counting and aggregation
- Recipe matching (exact, partial, extra items)
- Recipe processing (consumption, output spawning)
- Multiple update cycles (no duplication)

Run tests: `lua makelove tests`

## Future Directions

### Alternative Interaction Models

1. **Gesture-based Crafting**:
   - Place items in specific patterns around machine
   - Physical shape determines recipe
   - More intuitive but less precise

2. **Timed Minigames**:
   - Quick-time events during crafting
   - Better results with better timing
   - Adds skill-based progression

3. **Machine Programming**:
   - Scriptable machines (simple language)
   - Players create custom recipes/logic
   - Advanced automation for experienced players

### Cross-system Integration

- **Ages System**: Lock recipes behind Age tiers
- **Biomes**: Biome-specific machines or recipes
- **Multiplayer**: Shared machines, co-op crafting
- **Combat**: Craft weapons/ammo at workbenches
- **Building**: Craft decorative blocks, furniture
- **Farming**: Process crops, breed animals

## Conclusion

This machine system provides a solid foundation for in-world crafting. The prototype successfully demonstrates:
- Physical item interaction
- Recipe matching and processing
- Integration with existing entity and block systems
- Room for significant expansion

The modular design allows for easy addition of new machine types, recipes, and features without major refactoring.

**Next Steps**: Add meaningful recipes, implement a furnace machine, and begin tying machines to the Age progression system.
