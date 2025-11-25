# Registries

Registries in `registries/` provide centralized storage for game content (blocks, items, commands).

## Overview

| Registry | Purpose |
|----------|---------|
| `BlocksRegistry` | Block type definitions |
| `ItemsRegistry` | Item definitions |
| `CommandsRegistry` | Chat commands |

## Usage

```lua
local Registry = require "registries"

-- Get ID constants
local BLOCKS = Registry.blocks()  -- Block IDs
local ITEMS = Registry.items()    -- Item IDs

-- Get definitions
local stone = Registry.block(BLOCKS.STONE)
local gun = Registry.item(ITEMS.GUN)
```

## BlocksRegistry (`blocks.lua`)

Stores block definitions.

### Methods

| Method | Description |
|--------|-------------|
| `register(def)` | Register a block |
| `get(id)` | Get block by ID |
| `exists(id)` | Check if block exists |
| `get_ore_blocks()` | Get blocks with `ore_gen` |
| `iterate()` | Iterate all blocks |

### Block Definition

```lua
BlocksRegistry:register({
    id = BLOCKS.STONE,       -- Unique ID
    name = "Stone",          -- Display name
    solid = true,            -- Collision
    color = {0.5, 0.5, 0.5, 1},  -- RGBA
    tier = 1,                -- Mining tier required
    drops = function()       -- What drops when mined
        return BLOCKS.STONE, 1
    end,
    ore_gen = {              -- Optional: ore generation
        min_depth = 10,
        max_depth = 100,
        frequency = 0.07,
        threshold = 0.55,
        offset = 100,
    },
})
```

## ItemsRegistry (`items.lua`)

Stores item definitions.

### Methods

| Method | Description |
|--------|-------------|
| `register(def)` | Register an item |
| `get(id)` | Get item by ID |
| `exists(id)` | Check if item exists |
| `iterate()` | Iterate all items |

### Item Definition

```lua
ItemsRegistry:register({
    id = ITEMS.GUN,
    name = "Gun",
    weapon = {               -- Optional: weapon data
        cooldown = 0.2,
        bullet_speed = 400,
        bullet_width = 2,
        bullet_height = 2,
        bullet_color = {1, 1, 0, 1},
        bullet_gravity = 50,
        destroys_blocks = false,
    },
})
```

## CommandsRegistry (`commands.lua`)

Stores chat commands.

### Methods

| Method | Description |
|--------|-------------|
| `register(def)` | Register a command |
| `get(name)` | Get command by name |
| `execute(name, args)` | Execute command |
| `exists(name)` | Check if exists |

### Command Definition

```lua
CommandsRegistry:register({
    name = "heal",
    description = "Restore health",
    execute = function(args)
        G.player.health.current = 100
        return true, "Healed"
    end,
})
```
