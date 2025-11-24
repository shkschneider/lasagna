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
2. core/game.lua: High-level game controller. Manages World, Player, Camera, and Render pipeline.
3. core/object.lua: Recursive composition system. Automatically calls update/draw on all components based on priority.
4. components/: Component definitions with update/draw methods. Entities are composed of multiple components.
5. systems/: Thin coordinators that manage entity collections and handle cross-entity interactions.
6. world/: World simulation, terrain generation, block storage. Uses lazy generation for columns.
7. data/: Block and Item prototype definitions.

### Component-based Architecture

Lasagna uses a component-based architecture with recursive composition:

- **Components** contain data and behavior (update/draw methods)
- **Entities** are composed of multiple components (position, velocity, physics, visual, etc.)
- **Systems** are thin coordinators that manage entities and handle cross-entity logic
- **Object system** recursively calls update/draw on all components based on priority

Component priorities (lower = earlier):
- 10: Physics (gravity)
- 20: Velocity (position updates)
- 30: Bullet/Drop (lifetime, behavior)
- 50: Health (regeneration)
- 51: Stamina (regeneration)
- 100: Visual (rendering)

See `docs/component-architecture.md` for detailed documentation.

### Important patterns & invariants
- Components must assign update/draw methods to instances in new() constructor
- Components should check self.enabled before executing logic (for debugging)
- Systems coordinate (collision, pickup, spawning) while components implement (physics, rendering, behavior)
- Simple entities (bullets, drops) use full component-based update/draw
- Complex entities (player) selectively disable components and handle logic manually
- Use Object.update(entity, dt) to recursively call all component updates
- World stores blocks and should expose a canonical accessor: world:get_block_proto(z,col,row) which returns either a prototype table or nil.
- Inventory entries should be normalized to a single shape (recommended: { proto = <proto>, count = n }).
- Dropping items must never silently discard items: proto:drop(...) should exist or a default Item:drop spawns a Drop entity.
- Minimize global state (G.*). Prefer wiring modules through a Game object and dependency injection for testability and easier migration.

## Coding Conventions
- Indentation: 4 spaces
- Naming: snake_case for variables/functions, PascalCase for objects/classes, SCREAMING_SNAKE_CASE for constants
- Use local for variables/functions unless global is required
- Require dependencies at top of files
- Use the Object system in core/object.lua for recursive composition
- Components must assign update/draw methods to instances in new()
- Component update signature: function Component.update(self, dt, entity)
- Component draw signature: function Component.draw(self, entity, ...)
- All components should have priority and enabled fields

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
- Components can be tested independently using Lua 5.1 (see /tmp/test_components.lua for examples)
- Test component update/draw methods directly: `component:update(dt, entity)`
- Test enable/disable: `component.enabled = false` should prevent updates
- Add timing instrumentation in the main update loop under DEBUG to profile world, entity updates, and rendering.
- Run component tests: `lua5.1 /tmp/test_components.lua` (requires lua5.1 package)

## Migration notes (engine-agnostic guidance)
- Keep gameplay logic engine-agnostic where practical. Define a small Engine Abstraction Layer (EAL) mapping used Love APIs to simple functions (draw_rect, create_canvas, draw_image, get_mouse_pos, play_sound).
- If migration to Go/raylib is desired later, port deterministic systems first (world gen), verify parity, then physics, then rendering.

## Common tasks for contributors
- Adding block types: add to data/blocks.lua, ensure drop() behavior and test in-game.
- Adding components: create in components/, implement new() with update/draw assignment, set priority and enabled.
- Adding entities: compose from components/, use Object.update/draw for automatic component updates.
- Modifying player controls: edit systems/player.lua and systems/control.lua; change movement constants in systems/player.lua.
- Adding systems: create in systems/, manage entity collection, call Object.update on entities, handle cross-entity logic.

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
