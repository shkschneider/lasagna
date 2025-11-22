# Testing Guide for Lasagna v0.0 and v0.1

## What's Implemented

This implementation covers ROADMAP items v0.0 (Project Setup) and v0.1 (Core Playable Loop - MVP).

### v0.0 Features ✅
- Debug mode via `DEBUG=true` environment variable
- Fixed seed via `SEED=<number>` environment variable
- Window configuration in conf.lua

### v0.1 Features ✅

#### World & Layers
- Three-layer world system: -1 (back), 0 (main), 1 (front)
- Procedural terrain generation with seeded Perlin noise
- Lazy column generation (only generates visible areas)
- Layer-specific terrain variation (Layer 1: smoother/lower, Layer -1: rougher/higher)
- Ores spawn at different depths using blobs and veins
- Dirt layer (5-15 blocks deep) with grass on top exposed to air
- Coal spawns as blobs, metals spawn as veins with branching
- Surface resources (sand) on Layer 1
- Cobalt is rare and very deep (layer -1, depth > 40)

#### Player
- WASD or Arrow keys for horizontal movement
- Space, W, or Up arrow to jump
- Player size: BLOCK_SIZE×(BLOCK_SIZE*2) pixels (1 block wide, 2 blocks tall)
- With BLOCK_SIZE=16: player is 16×32 pixels
- AABB collision detection with proper physics
- Player renders as white rectangle

#### Layer System
- Q key: Switch to previous layer (max: -1), only when no collision in target layer
- E key: Switch to next layer (max: 1), only when no collision in target layer
- Active layer is fully visible
- Back layer (-1) is dimmed when not active
- Front layer (1) is semi-transparent when not active
- Current layer shown in UI
- Player can only interact with blocks on current layer

#### Inventory & Hotbar
- 9-slot hotbar at bottom of screen
- Stack size: 64 items per slot
- 1-9 keys select hotbar slots
- Selected slot highlighted in yellow
- Item count displayed on each slot
- Starting items: 64 Dirt, 32 Stone, 16 Wood

#### Mining & Placing
- Left-click to mine blocks
- Right-click to place blocks from selected hotbar slot
- Tier-gating: Omnitool tier must match or exceed block tier
- Mined blocks spawn drop entities

#### Drops & Pickup
- Destroyed blocks spawn drop entities
- Drops size: (BLOCK_SIZE/2)×(BLOCK_SIZE/2) pixels (half of block size)
- With BLOCK_SIZE=16: drops are 8×8 pixels
- Drops have physics (gravity, collision, friction)
- Drops automatically picked up when player is near (same layer only)
- Pickup has 0.5 second delay after spawn
- Drops despawn after 300 seconds

#### Rendering
- Layer canvas system for proper compositing
- Sky blue background
- Visual feedback for layer depth
- Smooth camera following player

#### UI
- Hotbar display at bottom
- Selected item name displayed above hotbar (centered)
- Layer indicator (top-left)
- Omnitool tier display (top-left)
- Player position in blocks (top-left)
- Mouse position in blocks with block name under cursor (top-left)
- Debug info when DEBUG=true (FPS, seed)

#### Block Types
- Air (transparent)
- Dirt (tier 0, brown)
- Grass (tier 0, green) - Dirt exposed to air becomes grass
- Stone (tier 0, gray)
- Wood (tier 0, brown/orange)
- Coal (tier 0, black) - Generated as blobs underground
- Copper Ore (tier 1, orange) - Generated as veins
- Tin Ore (tier 1, silver-gray) - Generated as veins
- Iron Ore (tier 2, brown-gray) - Generated as veins, deep layer -1
- Lead Ore (tier 2, blue-gray) - Generated as veins, deep layer -1
- Zinc Ore (tier 2, light gray) - Generated as veins, deep layer -1
- Cobalt Ore (tier 4, blue) - Rare, very deep veins, layer -1 only
- Sand (tier 0, tan) - Surface blobs on layer 1

## How to Run

### Normal mode
```bash
love .
```

### Debug mode
```bash
DEBUG=true love .
```

### Fixed seed
```bash
SEED=12345 love .
```

### Combined
```bash
DEBUG=true SEED=42 love .
```

## Controls

| Key | Action |
|-----|--------|
| WASD / Arrows | Move player |
| Space / W / Up | Jump |
| Q | Switch to previous layer (only when no collision) |
| E | Switch to next layer (only when no collision) |
| 1-9 | Select hotbar slot |
| Left Click | Mine block |
| Right Click | Place block |
| + / = | Increase omnitool tier (dev) |
| - / _ | Decrease omnitool tier (dev) |
| Delete | Reload world with same seed |
| T (debug) | Add test items to inventory |
| Escape | Quit game |

## Testing Checklist

### Basic Movement
- [ ] Player can move left/right with WASD or arrows
- [ ] Player can jump with Space, W, or Up
- [ ] Player collides with ground (AABB collision)
- [ ] Player collides with ceiling (AABB collision)
- [ ] Player collides with walls (AABB collision)
- [ ] Player is BLOCK_SIZE wide and BLOCK_SIZE*2 tall (1 block wide, 2 blocks tall)
- [ ] Camera follows player smoothly

### Layer System
- [ ] Q switches to previous layer (stops at -1)
- [ ] E switches to next layer (stops at 1)
- [ ] Layer switching only works when player can fit (no collision in target layer)
- [ ] Layer indicator updates in UI
- [ ] Visual appearance changes (dimming/transparency)
- [ ] Player only interacts with blocks on current layer

### Mining
- [ ] Left-clicking solid blocks removes them
- [ ] Mined blocks spawn drops
- [ ] Drops have physics (fall, bounce)
- [ ] Air blocks cannot be mined
- [ ] Tier 1 blocks (Copper) cannot be mined with tier 0 omnitool

### Placing
- [ ] Right-clicking empty space places block from hotbar
- [ ] Block is removed from inventory after placing
- [ ] Cannot place on solid blocks
- [ ] Selected slot is used for placement

### Inventory
- [ ] Hotbar shows 9 slots
- [ ] Selected slot is highlighted
- [ ] Item counts are displayed
- [ ] Items stack up to 64
- [ ] 1-9 keys select different slots

### Drops & Pickup
- [ ] Drops spawn at block center
- [ ] Drops are (BLOCK_SIZE/2)×(BLOCK_SIZE/2) pixels (half block size)
- [ ] Drops fall and collide with ground
- [ ] Walking near drop picks it up
- [ ] Drops only picked up on same layer
- [ ] Pickup respects inventory capacity
- [ ] Drops despawn after 5 minutes

### World Generation
- [ ] World generates on demand (lazy loading)
- [ ] Same seed produces same world
- [ ] Different layers have different terrain (Layer 1 smoother, Layer -1 rougher)
- [ ] Ores spawn deeper underground using blobs (coal, sand) and veins (metals)
- [ ] Surface has dirt layer (5-15 blocks) over stone
- [ ] Grass forms on dirt exposed to air
- [ ] Sand blobs spawn on Layer 1 surface
- [ ] Cobalt is very rare and very deep (layer -1, depth > 40)

### Debug Features
- [ ] DEBUG=true shows FPS
- [ ] DEBUG=true shows seed
- [ ] Player position shown in blocks (top-left)
- [ ] Mouse position shown in blocks with block name (top-left)
- [ ] Selected item name shown above hotbar
- [ ] T key adds test items (debug only)
- [ ] +/- keys adjust omnitool tier (clamped 0-10)
- [ ] Delete reloads world

## Known Limitations (Expected)

These are intentional omissions for v0.1 MVP:
- No crafting system (v0.2)
- No Age progression (v0.2)
- No machines (v0.2)
- No enemies (v0.3)
- No death/snapshot system (v0.4)
- No sound effects
- Simple placeholder graphics (colored rectangles)
- No multi-block structures
- Omnitool tier can be adjusted with +/- keys for development
- Inventory is hotbar only (no extra rows)

## Architecture Notes

### File Structure
All game code is in root directory (flat structure):
- `main.lua` - Entry point, Love2D callbacks
- `conf.lua` - Window and Love2D configuration
- `game.lua` - Main game controller
- `world.lua` - World generation and block storage
- `player.lua` - Player entity and physics
- `camera.lua` - Camera follow system
- `render.lua` - Rendering pipeline with layer canvases
- `blocks.lua` - Block prototype definitions
- `inventory.lua` - Inventory and hotbar system
- `entities.lua` - Entity system (drops, physics)
- `lib/` - Small utilities (log, colors, object)

### Design Principles
- Component-based approach (no OOP/inheritance)
- Engine-agnostic where practical
- Minimal dependencies (only Love2D built-ins)
- Deterministic world generation (seeded)
- Canonical block prototype system

## Future Work (v0.2+)

See ROADMAP.md for:
- Crafting and workbenches
- Age progression system
- Omnitool tier upgrades
- Processing machines (furnace, etc.)
- Inventory expansion (additional rows)
- Enemies and combat
- Death and snapshot restore
- Sound and improved graphics
