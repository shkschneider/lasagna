# Lasagna Architecture

This document describes the architectural patterns used in Lasagna, a 2D layered exploration and sandbox game built with LÖVE 2D.

## Overview

Lasagna uses a **composition-based architecture** inspired by Entity-Component-System (ECS) patterns, but simplified for Lua and LÖVE 2D. The key insight is that objects are composed of smaller objects, and the framework automatically calls lifecycle methods (`load`, `update`, `draw`, etc.) on all sub-objects recursively.

## Core Concepts

### The Object System (`core/object.lua`)

The `Object` is the foundation of Lasagna's architecture. It provides:

1. **Recursive Composition**: Any table property of an Object is treated as a potential sub-object
2. **Priority-Based Ordering**: Sub-objects are sorted by `priority` (lower = earlier)
3. **Automatic Method Dispatch**: Lifecycle methods are called on all sub-objects

```lua
local Object = require "core.object"

local MySystem = Object.new {
    id = "mysystem",
    priority = 50,
    -- Sub-objects can be added as properties
    someComponent = SomeComponent.new(),
}

function MySystem.load(self)
    -- Called during game initialization
end

function MySystem.update(self, dt)
    -- Called every frame
end

function MySystem.draw(self)
    -- Called every frame for rendering
end
```

#### How It Works

When you call `Object.update(entity, dt)`, the Object system:

1. Collects all table properties of `entity`
2. Sorts them by `priority` (cached for performance)
3. Calls `update(dt, entity)` on each sub-object that has an `update` method

This creates a tree of objects where lifecycle methods cascade down automatically.

#### Supported Lifecycle Methods

All LÖVE 2D callbacks are supported:
- `load(...)` - Initialization
- `update(dt)` - Game logic (receives parent entity as second parameter)
- `draw()` - Rendering (receives parent entity as parameter)
- `keypressed(key)`, `keyreleased(key)` - Keyboard input
- `mousepressed(x, y, button)`, `mousereleased(x, y, button)` - Mouse input
- `mousemoved(x, y, dx, dy)` - Mouse movement
- `wheelmoved(x, y)` - Mouse wheel
- `textinput(text)` - Text input
- `resize(width, height)` - Window resize
- `focus(focused)` - Window focus
- `quit()` - Game exit

### Fake ECS

Lasagna's architecture resembles ECS but with key differences:

| Traditional ECS | Lasagna |
|-----------------|---------|
| Entities are IDs | Entities are Objects (tables) |
| Components are pure data | Components can have behavior |
| Systems iterate over entities | Systems are Objects with components |
| Strict separation | Flexible composition |

#### Entity Definition

An **entity** in Lasagna is an Object with at minimum:
- `position`: VectorComponent (x, y, z coordinates)
- `velocity`: VectorComponent (vx, vy movement speed)

```lua
local entity = {
    id = uuid(),
    position = VectorComponent.new(100, 200, 0),
    velocity = VectorComponent.new(0, 0),
    gravity = PhysicsSystem.DEFAULT_GRAVITY,
    friction = PhysicsSystem.DEFAULT_FRICTION,
}
```

#### Component Pattern

Components are data containers that may include behavior:

```lua
local VectorComponent = {}

function VectorComponent.new(x, y, z)
    local instance = {
        id = "vector",
        priority = 20,
        enabled = true,
        x = x or 0,
        y = y or 0,
        z = z or 0,
    }
    -- Assign update method to instance
    instance.update = VectorComponent.update
    return instance
end

function VectorComponent.update(self, dt, entity)
    if not self.enabled then return end
    -- Apply velocity to position
    if entity and entity.velocity == self and entity.position then
        entity.position.x = entity.position.x + self.x * dt
        entity.position.y = entity.position.y + self.y * dt
    end
end
```

#### System Pattern

Systems are Objects that manage game logic:

```lua
local EntitySystem = Object.new {
    id = "entity",
    priority = 60,
    entities = {},
}

function EntitySystem.update(self, dt)
    for _, entity in ipairs(self.entities) do
        Object.update(entity, dt)  -- Update all components
    end
end
```

## Game Structure

### Global Game Object (`G`)

The game is a global Object accessible as `G`:

```lua
-- main.lua
G = require "core.game"
```

The Game object (`core/game.lua`) contains all systems as properties:

```lua
local Game = {
    priority = 0,
    state = GameStateComponent.new(GameStateComponent.BOOT),
    time = TimeComponent.new(1),
    world = require("systems.world"),
    player = require("systems.player"),
    entity = require("systems.entity"),
    -- ... more systems
}
```

When LÖVE calls `love.update(dt)`, we call `Object.update(G, dt)`, which cascades to all systems.

### Systems (`systems/`)

Systems are high-level game managers. Each system is an Object that handles a specific domain:

| System | Priority | Purpose |
|--------|----------|---------|
| `world` | 10 | World generation and block storage |
| `player` | 20 | Player entity and movement |
| `camera` | 30 | Camera following player |
| `entity` | 60 | Bullets, drops, and other entities |
| `physics` | - | Gravity and collision utilities |
| `storage` | - | Item storage (hotbar, backpack) |
| `control` | 80 | Input handling |
| `interface` | 110 | UI rendering |
| `debug` | 120 | Debug overlays |

**Key Systems:**

#### PlayerSystem
Special entity with custom physics handling. Has:
- `position`, `velocity` (VectorComponents)
- `hotbar`, `backpack` (StorageSystem instances)
- `health`, `stamina` (Components with UI)
- `omnitool` (Mining tool)

#### EntitySystem
Manages all game entities (bullets, drops). Provides:
- `newEntity(x, y, layer, vx, vy, type, gravity, friction)`
- `newBullet(...)` - Spawn projectile
- `newDrop(...)` - Spawn item drop

#### StorageSystem
Reusable storage container (array of StackComponents):
- `new(size)` - Create storage with N slots
- `selected_slot` - Currently selected slot
- `input(stack)` / `output(stack)` - Add/remove items
- `get_slot(i)` / `set_slot(i, stack)` - Direct access

### Components (`components/`)

Components are data containers with optional behavior:

| Component | Purpose |
|-----------|---------|
| `vector` | Position (x, y, z) or velocity (vx, vy) |
| `stack` | Item stack (block_id/item_id + count) |
| `health` | Health with max, regen, and UI |
| `stamina` | Stamina with max, regen, and UI |
| `projectile` | Bullet properties (damage, lifetime) |
| `itemdrop` | Drop properties (block_id, count) |
| `time` | Game time scale and pause |
| `gamestate` | Game state machine |

**Component Guidelines:**
1. Components should assign their `update`/`draw` methods to instances in `new()`
2. Use `priority` to control update order (lower = earlier)
3. Use `enabled` flag to disable automatic updates when needed
4. Components receive the parent entity as the second parameter in `update(self, dt, entity)`

## Priority System

Priority determines the order of updates and draws:

```
10 - Physics (gravity application)
20 - Velocity (position updates) / Player
30 - Behavior (entity-specific logic)
50 - Health, Stamina (regeneration)
60 - EntitySystem
80 - Control
100 - Visual (rendering)
110 - Interface (UI)
120 - Debug
```

Lower priority = updated/drawn first.

## Data Flow

```
love.update(dt)
    └── Object.update(G, dt)
        ├── WorldSystem.update()
        ├── PlayerSystem.update()
        │   └── Object.update(player, dt)
        │       ├── VectorComponent.update() [position - disabled]
        │       ├── VectorComponent.update() [velocity - disabled]
        │       ├── HealthComponent.update()
        │       └── StaminaComponent.update()
        ├── EntitySystem.update()
        │   └── for each entity:
        │       └── Object.update(entity, dt)
        │           ├── VectorComponent.update() [position]
        │           ├── VectorComponent.update() [velocity]
        │           └── BulletComponent/DropComponent.update()
        └── ... other systems
```

## Best Practices

1. **Use Object.new for Systems**: Systems should be created with `Object.new {...}`
2. **Assign Methods in new()**: Components must assign their methods to instances
3. **Check enabled Flag**: Components should respect `self.enabled`
4. **Use Priority**: Set appropriate priority for update order
5. **Keep Components Focused**: Each component should have a single responsibility
6. **Systems Coordinate**: Systems manage entity collections and cross-entity logic
7. **Avoid Global State**: Prefer passing dependencies through `G` or constructors
