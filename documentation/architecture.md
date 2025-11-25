# Lasagna Architecture

This document describes the high-level architecture and the non-ECS composition pattern used in Lasagna.

## Overview

Lasagna uses a **composition-based architecture** inspired by Entity-Component-System (ECS) but simplified for Lua. Objects are composed of smaller objects, and lifecycle methods cascade down automatically.

## The Global Game Object (`G`)

The game is a global Object accessible as `G` (defined in `main.lua`):

```lua
G = require "core.game"
```

`G` contains all systems as properties. When LÖVE calls `love.update(dt)`, we call `Object.update(G, dt)`, which cascades to all systems automatically.

```lua
-- core/game.lua
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

## Non-ECS Composition Pattern

### Traditional ECS vs Lasagna

| Traditional ECS | Lasagna |
|-----------------|---------|
| Entities are IDs | Entities are Objects (tables) |
| Components are pure data | Components can have behavior |
| Systems iterate over entities | Systems are Objects with components |
| Strict separation | Flexible composition |

### How It Works

The `Object` system (`core/object.lua`) provides recursive composition:

1. **Any table property** of an Object is treated as a potential sub-object
2. Sub-objects are **sorted by `priority`** (lower = earlier)
3. **Lifecycle methods** (`update`, `draw`, etc.) cascade to all sub-objects

```lua
local MySystem = Object.new {
    id = "mysystem",
    priority = 50,
    someComponent = SomeComponent.new(),  -- Sub-object
}

function MySystem.update(self, dt)
    -- This is called, and someComponent.update() is also called automatically
end
```

### Entity Definition

An **entity** is an Object with at minimum:
- `position`: VectorComponent (x, y, z)
- `velocity`: VectorComponent (vx, vy)

```lua
local entity = {
    id = uuid(),
    position = VectorComponent.new(100, 200, 0),
    velocity = VectorComponent.new(0, 0),
    gravity = PhysicsSystem.DEFAULT_GRAVITY,
    friction = PhysicsSystem.DEFAULT_FRICTION,
}
```

### Priority System

Priority determines update/draw order (lower = first):

```
10 - Physics
20 - Velocity / Player
30 - Behavior
50 - Health, Stamina
60 - EntitySystem
80 - Control
110 - Interface
120 - Debug
```

## Data Flow

```
love.update(dt)
    └── Object.update(G, dt)
        ├── WorldSystem.update()
        ├── PlayerSystem.update()
        │   └── Object.update(player, dt)
        │       ├── HealthComponent.update()
        │       └── StaminaComponent.update()
        ├── EntitySystem.update()
        │   └── for each entity:
        │       └── Object.update(entity, dt)
        └── ... other systems
```

## Best Practices

1. **Use `Object.new` for Systems**
2. **Assign methods in `new()`** for components
3. **Respect `enabled` flag** in components
4. **Set appropriate `priority`**
5. **Keep components focused** (single responsibility)
6. **Access globals via `G`** (e.g., `G.player`, `G.world`)
