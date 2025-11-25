# Lasagna

A 2D layered exploration and sandbox game built with LÖVE 2D.

## Game Overview

Lasagna is a procedurally generated world with three interactable layers (-1, 0, 1). Players explore, gather resources, build, and progress through Ages using the Omnitool.

### Core Features

- **Three Layers**: Back (-1), Main (0), Front (1) with parallax rendering
- **Omnitool**: Universal unbreakable tool, tier-gated by Age
- **Hotbar + Backpack**: 9-slot hotbar, 27-slot backpack (3×9)
- **Stack Size**: Fixed at 64 for all items
- **Death**: Automatic snapshot restore (no manual saves)

### Controls

| Key | Action |
|-----|--------|
| WASD | Movement |
| Q/E | Switch layers |
| 1-9 | Select hotbar slot |
| Left Click | Mine/Use |
| Right Click | Place block |

## Running the Game

```bash
love .                    # Run game
DEBUG=true love .         # Debug mode
SEED=12345 love .         # Fixed seed
```

Press `Delete` to hot-reload the world.

## Architecture

Lasagna uses a **composition-based architecture** (non-ECS). The global `G` object contains all systems, and lifecycle methods cascade automatically via the Object system.

```
main.lua          # Entry point, LÖVE callbacks
core/
  object.lua      # Composition system (recursive update/draw)
  game.lua        # Game object (assigned to global G)
  noise.lua       # Perlin noise for terrain
  generator.lua   # Terrain generation pipeline
systems/          # Game managers (player, world, entity, etc.)
components/       # Data containers (vector, stack, health, etc.)
registries/       # Content registries (blocks, items, commands)
data/             # Game content definitions
```

### Key Concepts

**Entity**: Object with `position` and `velocity` (VectorComponents)

**System**: Object managing a game domain (e.g., PlayerSystem, EntitySystem)

**Component**: Data container with optional behavior (e.g., StackComponent)

**StorageSystem**: Array of StackComponents for inventory slots

### Priority Order

Systems/components update by priority (lower = first):
```
10 Physics → 20 Player → 60 Entity → 80 Control → 110 UI
```

## Documentation

See `documentation/` for detailed docs:
- `architecture.md` - Composition pattern, Game object
- `core.md` - Core modules (Object, noise, generator)
- `systems.md` - System overview
- `components.md` - Component overview
- `registries.md` - Content registries
- `data.md` - Game content (blocks, items, commands)
- `luax.md` - Lua extensions library

## Game Design

### Resources & Tiers

Ores spawn in veins with tier-gated mining:
- **Tier 0**: Dirt, Grass, Sand, Wood
- **Tier 1**: Stone, Coal
- **Tier 2**: Copper, Tin
- **Tier 3**: Iron
- **Tier 4+**: Silver, Gold, Gems

### Omnitool Progression

Wood → Stone → Copper → Bronze → Iron → Steel → Cobalt

### Lore

The player is a **Seed** sent by the **Hive** to colonize worlds. Success is measured by Age progression.

## License

See LICENSE file.
