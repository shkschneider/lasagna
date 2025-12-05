# Sprite System

## Overview

The sprite system handles loading and rendering animated sprite sheets for game entities, starting with the player character.

## Architecture

### Module: `src/ui/sprites.lua`

The sprites module is responsible for:
- Loading sprite sheet images during game initialization
- Managing sprite state and frames
- Providing helper functions for drawing animated sprites

### Loading

Sprites are loaded during the game's loading phase (see `src/ui/loader.lua`):
1. Menu loads (5%)
2. **Sprites load (8%)** ← New
3. World generates (10-90%)
4. Save data applies (95-99%)
5. Transition to play (100%)

## Player Sprites

All player sprite sheets are located in `assets/player/`:

| Sprite File | Frames | Usage |
|------------|--------|-------|
| `idle_4.png` | 4 | Standing still (slow animation) |
| `walk_6.png` | 6 | Regular horizontal movement |
| `run_6.png` | 6 | Sprinting (shift + movement) |
| `jump_8.png` | 8 | Jumping and falling |
| `attack_4.png` | 4 | Range weapon attacks (future) |
| `attack_6.png` | 6 | Melee weapon attacks (future) |
| `climb_4.png` | 4 | Climbing ladders (future) |
| `hurt_4.png` | 4 | Taking damage (future) |
| `death_8.png` | 8 | Death animation |
| `player.png` | 1 | Fallback/default sprite |

### Sprite Sheet Format

Each sprite sheet is a horizontal strip of frames:
```
[Frame 0][Frame 1][Frame 2]...[Frame N-1]
```

The frame count is encoded in the filename (e.g., `walk_6` = 6 frames).

## Animation System

### Player Animation State

The player tracks animation state in `self.animation`:
```lua
{
    time = 0,              -- Time accumulator for frame updates
    frame = 0,             -- Current frame index (0-based)
    fps = 10,              -- Animation speed (frames per second)
    facing_right = true    -- Sprite horizontal direction
}
```

### State-to-Sprite Mapping

The player's `draw()` function maps game state to sprites:

1. **Dead** → `death_8`
2. **Jumping/Falling** → `jump_8`
3. **Moving + Sprinting** → `run_6`
4. **Moving** → `walk_6`
5. **Standing** → `idle_4`
6. **Fallback** → `default` (player.png)

### Direction Handling

Sprites are flipped horizontally based on `animation.facing_right`:
- `true` → sprite draws normally
- `false` → sprite is mirrored (facing left)

Direction updates when `velocity.x` changes sign.

## Usage

### Drawing Sprites

```lua
G.ui.sprites:draw_player(
    sprite_name,      -- "walk_6", "idle_4", etc.
    x, y,             -- Screen position
    frame,            -- Current frame index (0-based)
    facing_right,     -- true/false for direction
    scale             -- Optional scale multiplier (default 1.0)
)
```

### Getting Frame Dimensions

```lua
local width, height = G.ui.sprites:get_frame_size("walk_6")
```

## Future Enhancements

- Attack animations when using weapons
- Hurt animation on damage (brief flash/override)
- Climb animation for ladders
- Crouch-specific animations
- Support for other entities (enemies, NPCs)
- Animation blending/transitions
- Particle effects (dust, impacts)

## Technical Details

### Pixel-Perfect Rendering

Sprites use `nearest` filtering for sharp pixel art:
```lua
sprite:setFilter("nearest", "nearest")
```

### Quad System

Each frame is rendered using Love2D quads, allowing efficient sprite sheet rendering without splitting files.

### Fallback System

If a sprite fails to load or doesn't exist, the system falls back to:
1. `player.default` (player.png)
2. Silent skip (draws nothing)

This ensures the game never crashes due to missing sprites.
