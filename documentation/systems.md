# Systems

Systems are high-level game managers in `systems/`. Each is an Object with a specific responsibility.

## Overview

| System | Priority | Purpose |
|--------|----------|---------|
| `world` | 10 | World generation, block storage |
| `player` | 20 | Player entity, movement, collision |
| `camera` | 30 | Camera following player |
| `entity` | 60 | Bullets, drops, entities |
| `control` | 80 | Input handling |
| `interface` | 110 | UI rendering |
| `debug` | 120 | Debug overlays |
| `physics` | - | Gravity/collision utilities |
| `storage` | - | Item storage container |
| `mining` | - | Block mining |
| `building` | - | Block placement |
| `weapon` | - | Shooting |
| `chat` | - | Chat system |
| `lore` | - | Lore/story |
| `generator` | - | Terrain generation |

## Key Systems

### PlayerSystem (`player.lua`)

Player entity with custom physics. Properties:
- `position`, `velocity` - VectorComponents
- `hotbar`, `backpack` - StorageSystem (9 and 27 slots)
- `health`, `stamina` - Components with UI
- `omnitool` - Mining tool with tier

### EntitySystem (`entity.lua`)

Manages all game entities:
- `newBullet(x, y, layer, vx, vy, ...)` - Spawn projectile
- `newDrop(x, y, layer, block_id, count)` - Spawn item drop
- Updates all entities with `Object.update()`

### StorageSystem (`storage.lua`)

Reusable storage container (array of StackComponents):
- `new(size)` - Create with N slots
- `selected_slot` - Currently selected
- `has(stack)` / `can_input(stack)` / `can_output(stack)` - Check operations
- `input(stack)` / `output(stack)` - Add/remove
- `get_slot(i)` / `set_slot(i, stack)` - Direct access
- `get_selected()` / `remove_from_selected(count)` - Selected slot operations

### PhysicsSystem (`physics.lua`)

Physics utilities (not an Object, just functions):
- `DEFAULT_GRAVITY` = 800
- `DEFAULT_FRICTION` = 0.95
- `apply_gravity(entity, dt)` - Apply gravity to velocity
- `check_collision(entity, world)` - Collision detection

### WorldSystem (`world.lua`)

World management:
- `get_block_id(z, col, row)` / `set_block(z, col, row, id)` - Block access
- `world_to_block(x, y)` / `block_to_world(col, row)` - Coordinate conversion
- `find_spawn_position(layer)` - Find valid spawn
- Lazy column generation

### ControlSystem (`control.lua`)

Input handling:
- Movement keys (WASD)
- Hotbar selection (1-9)
- Layer switching (Q/E)
- Mouse input delegation

### InterfaceSystem (`interface.lua`)

UI rendering:
- Hotbar display
- Health/stamina bars
- Debug info
- Cursor highlight
