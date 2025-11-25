# Save System

The save system handles persisting and restoring game state to/from `.sav` files. It uses the [binser](https://github.com/bakpakin/binser) library for efficient binary serialization.

## Overview

The save system is designed to support the death mechanism by allowing the game to:
1. **Save** the current game state (world changes, player position, inventory, etc.)
2. **Load** a previously saved state to restore the game after death

## Save File Location

Save files are stored in LÖVE's save directory:
- **Windows**: `%APPDATA%/LOVE/lasagna/world.sav`
- **macOS**: `~/Library/Application Support/LOVE/lasagna/world.sav`
- **Linux**: `~/.local/share/love/lasagna/world.sav`

The save directory is configured by `t.identity = "lasagna"` in `conf.lua`.

## Save File Format

The save file is a binary-serialized Lua table with the following structure:

```lua
{
    -- Game version for compatibility checking
    version = {
        major = 0,          -- Major version number
        minor = 1,          -- Minor version number
        patch = nil,        -- Patch version (optional)
    },

    -- World seed for terrain regeneration
    seed = 1234567890,      -- Number used to regenerate procedural terrain

    -- Block changes from generated terrain
    -- Only stores blocks that differ from procedurally generated terrain
    changes = {
        [-1] = {            -- Layer -1 (back layer)
            [col] = {       -- Column index
                [row] = block_id,  -- Row index -> block ID
                ...
            },
            ...
        },
        [0] = {...},        -- Layer 0 (main layer)
        [1] = {...},        -- Layer 1 (front layer)
    },

    -- Player state
    player = {
        position = {
            x = 256.0,      -- World X coordinate
            y = 128.0,      -- World Y coordinate
            z = 0,          -- Layer (z-index)
        },
        velocity = {
            x = 0.0,        -- Horizontal velocity
            y = 0.0,        -- Vertical velocity
        },
        health = {
            current = 100,  -- Current health points
            max = 100,      -- Maximum health points
        },
        stamina = {
            current = 100,  -- Current stamina points
            max = 100,      -- Maximum stamina points
        },
        omnitool = {
            tier = 1,       -- Omnitool tier (1-4)
        },
        hotbar = {          -- 9-slot hotbar
            size = 9,
            selected_slot = 1,
            slots = {
                [1] = {item_id = "omnitool", count = 1},
                [2] = nil,  -- Empty slot
                ...
            },
        },
        backpack = {        -- 27-slot backpack (3 rows of 9)
            size = 27,
            selected_slot = 1,
            slots = {...},
        },
    },
}
```

## Block Changes

The save system only stores **changes** from procedurally generated terrain, not the entire world. This makes save files compact and efficient:

1. On save: Only blocks modified by the player (mined or placed) are stored
2. On load: The world is regenerated from the seed, then changes are applied on top

This approach means:
- Save files remain small regardless of how much of the world has been explored
- Loading is fast because terrain doesn't need to be stored/loaded

## Usage

### Saving the Game

```lua
-- Save current game state
G.save:save()
```

### Loading a Save

```lua
-- Check if save exists
if G.save:exists() then
    -- Load save data
    local save_data = G.save:load()
    if save_data then
        -- Apply to current game state
        G.save:apply_save_data(save_data)
    end
end
```

### Deleting a Save

```lua
-- Delete save file
G.save:delete()
```

### Getting Save Info

```lua
-- Get save file information
local info = G.save:get_info()
if info then
    print("Save path:", info.path)
    print("Save size:", info.size, "bytes")
    print("World seed:", info.seed)
end
```

## Version Compatibility

The save system includes version information for compatibility checking:

- **Major version mismatch**: May cause issues, warning logged
- **Minor version mismatch**: Usually compatible, warning logged
- **Patch version mismatch**: Always compatible

When loading a save from a different version, the system logs a warning but attempts to load anyway. Future versions may add migration logic for breaking changes.

## API Reference

### SaveSystem

| Method | Description |
|--------|-------------|
| `save()` | Save current game state to file |
| `load()` | Load save data from file (returns table or nil) |
| `apply_save_data(data)` | Apply loaded save data to current game state |
| `exists()` | Check if save file exists |
| `delete()` | Delete save file |
| `get_info()` | Get save file metadata |
| `get_save_path()` | Get full path to save file |
| `create_save_data()` | Create save data table from current state |

## Implementation Notes

### Serialization

The save system uses [binser](https://github.com/bakpakin/binser) for serialization because:
- Binary format is compact and efficient
- Handles Lua tables, numbers, strings, booleans, and nil
- Fast serialization and deserialization
- MIT licensed

### File Operations

Save files are written using LÖVE's `love.filesystem` API, which:
- Writes to the save directory (not the game directory)
- Is sandboxed for security
- Works cross-platform

### Error Handling

The save system includes error handling for:
- Missing save files
- Corrupted save data
- Version mismatches
- File write failures

All errors are logged via the `Log` system.

## Future Enhancements

- [ ] Multiple save slots
- [ ] Auto-save on death (snapshot mechanism)
- [ ] Save file compression
- [ ] Save file encryption (for anti-cheat)
- [ ] Cloud save support
