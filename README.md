# Lasagna

A 2D layered exploration and sandbox game built with LÖVE 2D.

## Game Overview

Lasagna is a procedurally generated world with three interactable layers (-1, 0, 1).
Players explore, gather resources, build, and progress through Ages using the Omnitool.

### Core Features

- **Three Layers**: Back (-1), Main (0), Front (1) with parallax rendering
- **Omnitool**: Universal unbreakable tool, tier-gated by Age
- **Hotbar + Backpack**: 9-slot hotbar, 27-slot backpack (3×9)
- **Death**: Automatic snapshot restore

### Controls

| Key | Action |
|-----|--------|
| WASD | Movement |
| Q/E | Switch layers |
| 1-9 | Select hotbar slot |
| Left Click | Mine/Use |
| Right Click | Place block |

## Test & Run

```bash
lua makelove tests && lua makelove play

love .                    # Run game
DEBUG=true love .         # Debug mode
SEED=12345 love .         # Fixed seed
```

## Architecture

Lasagna uses a **composition-based architecture** (non-ECS).
The global `G` object contains all systems, and lifecycle methods cascade automatically via the Object system.

```
main.lua          # Entry point, LÖVE callbacks
...               # WIP
```

## Game Design

### Resources & Tiers

Ores spawn in veins with tier-gated mining:

- **Tier 0**: Dirt, Grass, Sand, Wood
- **Tier 1**: Stone, Coal
- **Tier 2**: Copper, Tin
- **Tier 3**: Iron
- **Tier 4+**: Silver, Gold, Gems

**Omnitool Progression:**

> Wood → Stone → Copper → Bronze → Iron → Steel → Cobalt

### Lore

The player is a **Seed** sent by the **Hive** to colonize worlds.
Success is measured by Age progression.

## License

See LICENSE file.
