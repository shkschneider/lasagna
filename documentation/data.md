# Data

The `data/` directory contains game content definitions that register with registries.

## Structure

```
data/
├── blocks/         # Block definitions
│   ├── ids.lua     # Block ID constants
│   ├── base.lua    # Basic blocks (air, dirt, stone, etc.)
│   └── ores.lua    # Ore blocks with generation data
├── items/          # Item definitions
│   ├── ids.lua     # Item ID constants
│   ├── omnitool.lua # Omnitool item
│   └── weapons.lua  # Gun, rocket launcher
├── commands/       # Chat commands
│   ├── god.lua     # God mode
│   ├── heal.lua    # Restore health
│   ├── ping.lua    # Test command
│   ├── seed.lua    # Show world seed
│   └── teleport.lua # Teleport player
└── lore/           # Story/lore content
    ├── ages.lua    # Game ages/eras
    └── messages.lua # Lore messages
```

## Blocks (`data/blocks/`)

### IDs (`ids.lua`)

Numeric constants for block types:
```lua
local BlockRef = {
    AIR = 0,
    DIRT = 1,
    GRASS = 2,
    STONE = 3,
    -- ...
}
```

### Base Blocks (`base.lua`)

Basic blocks: Air, Dirt, Grass, Stone, Sand, Wood, Bedrock

### Ores (`ores.lua`)

Ore blocks organized by tier:
- **Tier 1**: Coal
- **Tier 2**: Copper, Tin
- **Tier 3**: Iron
- **Tier 4**: Silver, Gold
- **Tier 5+**: Gems (Ruby, Sapphire, etc.)

Each ore has `ore_gen` for world generation:
```lua
ore_gen = {
    min_depth = 10,      -- Minimum depth from surface
    max_depth = 100,     -- Maximum depth
    frequency = 0.07,    -- Noise frequency
    threshold = 0.55,    -- Noise threshold
    offset = 100,        -- Noise offset for variety
}
```

## Items (`data/items/`)

### Omnitool (`omnitool.lua`)

The universal mining tool that progresses through tiers.

### Weapons (`weapons.lua`)

| Weapon | Cooldown | Speed | Destroys Blocks |
|--------|----------|-------|-----------------|
| Gun | 0.2s | 400 | No |
| Rocket Launcher | 0.8s | 300 | Yes |

## Commands (`data/commands/`)

Chat commands (prefix with `/`):

| Command | Description |
|---------|-------------|
| `/god` | Toggle god mode |
| `/heal` | Restore health/stamina |
| `/ping` | Test command |
| `/seed` | Show world seed |
| `/tp x y` | Teleport to coordinates |

## Lore (`data/lore/`)

Story content:
- **Ages**: Game progression eras
- **Messages**: Discoverable lore text

## Adding Content

### New Block

1. Add ID to `data/blocks/ids.lua`
2. Register in `data/blocks/base.lua` or create new file
3. Require in `data/blocks/init.lua`

### New Item

1. Add ID to `data/items/ids.lua`
2. Register in new file under `data/items/`
3. Require in `data/items/init.lua`

### New Command

1. Create file in `data/commands/`
2. Require in `data/commands/init.lua`
