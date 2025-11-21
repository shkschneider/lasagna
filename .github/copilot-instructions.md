```markdown
# GitHub Copilot Instructions for Lasagna

## Project Overview

Lasagna is a 2D layered exploration and sandbox game prototype implemented in Lua using the LÖVE 2D engine. The design centers on procedural, multi-layer worlds, resource progression through "Ages", and a single-player exploratory loop. The engine choice (LÖVE) supports rapid iteration and is sufficient for a prototype. Keep engine-agnostic gameplay where feasible to ease future migration.

Key gameplay points (from README):
- Three interactable layers: -1 (back), 0 (main), 1 (front). Player interacts only with the current layer.
- Layer rendering: front is semi-transparent, back is dimmed; parallax effects optional.
- Inventory: hotbar of 9 slots; storage grows by 9-slot rows per Age. Stack size fixed at 64.
- Omnitool: single unbreakable tool that progresses by Age tiers and gates resource access.
- Death: automatic snapshot restore to a previous world/player snapshot (no manual save).
- Core loop: exploration, gather, build, craft, progress Ages.

## Architecture

### Core Components
1. main.lua: Entry point. Handles window setup and Love callbacks. Delegates to the Game object for update/draw and input handling.
2. game.lua: High-level game controller. Manages World, Player, Camera, and Render pipeline.
3. world/: World simulation, terrain generation, block storage, and entity registry. Uses lazy generation for columns.
4. entities/: Player, bullets, rockets, drops, and other moving objects. Each entity implements update(dt, world, player) and draw().
5. data/: Block and Item prototype definitions. Prototypes must follow a minimal interface (name, max_stack, optional drop function).
6. lib/: Small dependencies (object system, noise, logging).

### Important patterns & invariants
- World stores blocks and should expose a canonical accessor: world:get_block_proto(z,col,row) which returns either a prototype table or nil.
- Inventory entries should be normalized to a single shape (recommended: { proto = <proto>, count = n }).
- Dropping items must never silently discard items: proto:drop(...) should exist or a default Item:drop spawns a Drop entity.
- Minimize global state (G.*). Prefer wiring modules through a Game object and dependency injection for testability and easier migration.
- Centralize canvas/rendering in a RenderManager: create and manage layer canvases in one place and composite to screen.

## Coding Conventions
- Indentation: 4 spaces
- Naming: snake_case for variables/functions, PascalCase for objects/classes, SCREAMING_SNAKE_CASE for constants
- Use local for variables/functions unless global is required
- Require dependencies at top of files
- Use the Object system in lib/object.lua for class-like definitions

## Development Workflow

Running the game:

```
love .
```

Debug mode:

```
DEBUG=true love .
```

Use a fixed seed for reproducible terrain:

```
SEED=12345 love .
```

Hot reload world:
- Press Delete to reload the world with the current seed.

## Testing & Instrumentation
- Add a small test harness for headless checks: inventory add/remove, block place/remove, drop spawn, entity lifecycle.
- Add timing instrumentation in the main update loop under DEBUG to profile world, entity updates, and rendering.

## Migration notes (engine-agnostic guidance)
- Keep gameplay logic engine-agnostic where practical. Define a small Engine Abstraction Layer (EAL) mapping used Love APIs to simple functions (draw_rect, create_canvas, draw_image, get_mouse_pos, play_sound).
- If migration to Go/raylib is desired later, port deterministic systems first (world gen), verify parity, then physics, then rendering.

## Common tasks for contributors
- Adding block types: add to data/blocks.lua, ensure drop() behavior and test in-game.
- Adding entities: add to entities/, implement update and draw, register in world entity registry.
- Modifying player controls: edit entities/player.lua; change movement constants in game.lua.

## Notes for Copilot and automation
- When generating code, prefer small focused diffs and include tests where possible.
- Preserve data prototype interfaces and add normalization at module boundaries (Inventory.add, world.set_block).
- Avoid introducing new global state; if needed, wire through Game or module constructors.

## CLI commands

```
# Run game
love .

# Debug mode
DEBUG=true love .

# Specific seed
SEED=42 love .

# Check Lua syntax
luac -p **/*.lua
```

```
