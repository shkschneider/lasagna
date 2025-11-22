# Systems and Components Architecture

## Overview

This document describes the modular systems and components architecture implemented in Lasagna.

## File Structure

```
components/
  init.lua          # Shared component constants/definitions
  position.lua      # Position component
  velocity.lua      # Velocity component
  physics.lua       # Physics component
  collider.lua      # Collider component
  visual.lua        # Visual component
  layer.lua         # Layer component
  inventory.lua     # Inventory component
  omnitool.lua      # Omnitool component
  drop.lua          # Drop component
  camera.lua        # Camera component
  gamestate.lua     # GameState component
  timescale.lua     # TimeScale component
  worlddata.lua     # WorldData component
  keyboardstate.lua # KeyboardState component
  mousestate.lua    # MouseState component

systems/
  init.lua          # Shared system constants/definitions (priorities)
  game.lua          # GameSystem (priority 0)
  world.lua         # WorldSystem (priority 10)
  player.lua        # PlayerSystem (priority 20)
  mining.lua        # MiningSystem (priority 60)
  drop.lua          # DropSystem (priority 70)
  camera.lua        # CameraSystem (priority 90)
  render.lua        # RenderSystem (priority 100)

system_manager.lua  # System lifecycle and execution manager
```

## Design Principles

1. **No inheritance** - Plain Lua tables only
2. **Modular and independent** - Each entity has its own component instances
3. **Minimal dependencies** - Systems depend only on libraries and globals
4. **Priority-based execution** - Systems sorted by priority on push()
5. **Clear separation** - Components are pure data, systems contain logic

## Components

Components are **pure data structures** with factory functions:

```lua
-- Example: Position component
local Position = {}

function Position.new(x, y, layer)
    return {
        x = x or 0,
        y = y or 0,
        layer = layer or 0,
    }
end

return Position
```

### Component List

- **Position** - `{x, y, layer}` - World coordinates
- **Velocity** - `{vx, vy}` - Movement vector
- **Physics** - `{on_ground, gravity, friction}` - Physics properties
- **Collider** - `{width, height}` - Collision bounds
- **Visual** - `{color, width, height}` - Render data
- **Layer** - `{current_layer}` - Layer state
- **Inventory** - `{slots, selected_slot, hotbar_size, max_stack}` - Item storage
- **Omnitool** - `{tier}` - Mining tier
- **Drop** - `{block_id, count, lifetime, pickup_delay}` - Drop data
- **Camera** - `{x, y, target_x, target_y, smoothness}` - Camera state
- **GameState** - `{state, debug, seed}` - Game state data
- **TimeScale** - `{scale, paused}` - Time manipulation
- **WorldData** - `{seed, width, height, layers, generated_columns}` - World storage
- **KeyboardState** - `{keys_down, keys_pressed}` - Keyboard state (future)
- **MouseState** - `{x, y, buttons}` - Mouse state (future)

## Systems

Systems contain **game logic** and operate on components:

```lua
-- Example: PlayerSystem structure
local PlayerSystem = {
    priority = 20,
    components = {},
}

function PlayerSystem:load(x, y, layer, world_system)
    -- Initialize components
    self.components.position = Position.new(x, y, layer)
    self.components.velocity = Velocity.new(0, 0)
    -- ...
end

function PlayerSystem:update(dt)
    -- System logic using components
end

function PlayerSystem:draw(camera_x, camera_y)
    -- Rendering logic
end

return PlayerSystem
```

### System List (by priority)

1. **GameSystem** (priority: 0)
   - Manages game state, time scale, debug mode
   - Components: GameState, TimeScale
   - Methods: load, update, draw, keypressed

2. **WorldSystem** (priority: 10)
   - World generation, block storage, world queries
   - Components: WorldData
   - Methods: load, get_block, set_block, get_block_proto, world_to_block, block_to_world

3. **PlayerSystem** (priority: 20)
   - Player entity, movement, inventory management
   - Components: Position, Velocity, Physics, Collider, Visual, Layer, Inventory, Omnitool
   - Methods: load, update, draw, keypressed, add_to_inventory, remove_from_selected

4. **MiningSystem** (priority: 60)
   - Block mining and placing logic
   - Methods: load, mousepressed, mine_block, place_block

5. **DropSystem** (priority: 70)
   - Drop entity management, physics, pickup
   - Manages entities with: Position, Velocity, Physics, Drop components
   - Methods: load, create_drop, update, draw

6. **CameraSystem** (priority: 90)
   - Camera positioning and smooth following
   - Components: Camera
   - Methods: load, update, get_offset, resize

7. **RenderSystem** (priority: 100)
   - All rendering operations (runs last)
   - Methods: load, draw, draw_world, composite_layers, draw_ui, resize

## System Manager

The `SystemManager` handles system lifecycle and execution:

```lua
local SystemManager = require("system_manager")

-- Push systems (automatically sorted by priority)
SystemManager:push(GameSystem)
SystemManager:push(WorldSystem)
SystemManager:push(PlayerSystem)
-- ...

-- Execute all systems in priority order
SystemManager:load(...)
SystemManager:update(dt)
SystemManager:draw()
SystemManager:keypressed(key)
SystemManager:mousepressed(x, y, button)
SystemManager:resize(width, height)
```

## Execution Flow

```
main.lua
  ↓
SystemManager
  ↓
  ├─→ GameSystem (priority 0) - time scale, game state
  ├─→ WorldSystem (priority 10) - world queries
  ├─→ PlayerSystem (priority 20) - player updates
  ├─→ MiningSystem (priority 60) - mining logic
  ├─→ DropSystem (priority 70) - drop physics
  ├─→ CameraSystem (priority 90) - camera following
  └─→ RenderSystem (priority 100) - rendering
```

## Usage Example

```lua
-- Create a new drop entity
DropSystem:create_drop(x, y, layer, block_id, count)

-- Get player position
local x, y, layer = PlayerSystem:get_position()

-- Query world block
local block_proto = WorldSystem:get_block_proto(layer, col, row)

-- Add item to inventory
PlayerSystem:add_to_inventory(block_id, count)
```

## Future Extensions

- **InputSystem** - Centralized input handling
- **PhysicsSystem** - Generalized physics for all entities
- **CollisionSystem** - Collision detection and response
- **LayerSystem** - Layer management and transitions
- **AISystem** - Enemy behavior (future)
- **ParticleSystem** - Visual effects (future)

## Migration Notes

The old `game.lua`, `world.lua`, `player.lua`, `entities.lua`, `camera.lua`, and `render.lua` modules are still present but unused. They can be removed once the new system is fully tested.

## Testing

To test the new architecture:

```bash
# Normal run
love .

# Debug mode
DEBUG=true love .

# Fixed seed
SEED=12345 love .

# Combined
DEBUG=true SEED=42 love .
```

Key features to test:
- Player movement and collision
- Layer switching (Q/E)
- Mining blocks (left click)
- Placing blocks (right click)
- Drop pickup
- Hotbar selection (1-9)
- World reload (Delete key)
- Debug mode toggle (Backspace)
