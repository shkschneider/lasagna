# Components Architecture

## Overview

The Lasagna game uses a component-based architecture built on top of the `core/object` system. This architecture enables **recursive composition** where systems and entities are composed of reusable components.

## Core Principles

1. **Components are data + behavior**: Components encapsulate both data and the methods to operate on that data
2. **Systems coordinate, components execute**: Systems manage collections of entities, while components contain the actual logic
3. **Global G access**: All components and systems can read from the global `G` (Game) object for coordination
4. **Self-contained entities**: Entities (like bullets and drops) have their own `load()`, `update(dt)`, and `draw()` methods

## Directory Structure

```
components/          # Component definitions
├── Basic Data Components
│   ├── position.lua    # 2D position with layer (x, y, z)
│   ├── velocity.lua    # 2D velocity (vx, vy)
│   ├── physics.lua     # Physics properties (gravity, friction)
│   ├── collider.lua    # Collision bounds (width, height)
│   ├── visual.lua      # Rendering properties (color, width, height)
│   └── layer.lua       # Layer management
│
├── Player Components
│   ├── health.lua      # Health management
│   ├── stamina.lua     # Stamina management
│   ├── stance.lua      # Movement stance (standing, jumping, falling)
│   ├── inventory.lua   # Item storage
│   └── omnitool.lua    # Tool progression
│
├── Game State Components
│   ├── gamestate.lua   # Game state tracking
│   ├── timescale.lua   # Time scaling and pause
│   ├── worlddata.lua   # World generation data
│   └── camera.lua      # Camera positioning
│
└── Entity Components (with update/draw)
    ├── bullet.lua      # Self-contained bullet entities
    └── drop.lua        # Self-contained drop entities
```

## Component Types

### 1. Basic Data Components

Simple data holders with minimal methods. Used as building blocks for entities.

**Example: Position Component**
```lua
local Position = require "components.position"
local pos = Position.new(x, y, z)
-- Access: pos.x, pos.y, pos.z
-- Method: pos:tostring()
```

### 2. Entity Components

Self-contained entities with `update(dt)` and `draw()` methods. These components create complete entities that manage their own lifecycle.

**Example: Bullet Component**
```lua
local Bullet = require "components.bullet"
local entity = Bullet.create_entity(x, y, layer, vx, vy, width, height, color, gravity, destroys_blocks)
-- The entity has:
--   - position, velocity, physics, bullet components
--   - update(self, dt) method
--   - draw(self) method
--   - remove_me flag for lifecycle management
```

### 3. Game State Components

Components that manage game state and configuration.

**Example: GameState Component**
```lua
local GameState = require "components.gamestate"
local state = GameState.new(GameState.PLAY)
-- Constants: BOOT, LOAD, PLAY, PAUSE, QUIT
-- Method: state:tostring()
```

## How Systems Use Components

Systems act as **coordinators** that:
1. Manage collections of entities
2. Delegate to entity components for updates and drawing
3. Handle creation and removal of entities

**Example: Bullet System**
```lua
-- Old approach: System contained all logic
function BulletSystem.update(self, dt)
    for i = #self.entities, 1, -1 do
        local ent = self.entities[i]
        -- 50+ lines of update logic here
    end
end

-- New approach: System delegates to component
function BulletSystem.update(self, dt)
    for i = #self.entities, 1, -1 do
        local ent = self.entities[i]
        Object.update(ent, dt)  -- Component handles its own update
        if ent.remove_me then
            table.remove(self.entities, i)
        end
    end
end
```

## Global G Object

The global `G` object (Game) provides access to all systems:
```lua
G.player    -- Player system with position, velocity, health, etc.
G.world     -- World system for block queries
G.camera    -- Camera system for screen coordinates
G.bullet    -- Bullet system for creating projectiles
G.drop      -- Drop system for creating item drops
G.chat      -- Chat system
G.ui        -- UI system
-- etc.
```

Components can access `G` to interact with other systems:
```lua
-- Example from bullet component update
local col, row = G.world:world_to_block(self.position.x, self.position.y)
local block_def = G.world:get_block_def(self.position.z, col, row)

-- Example from drop component update
local player_x, player_y, player_z = G.player:get_position()
G.player:add_to_inventory(self.drop.block_id, self.drop.count)
```

## Creating New Components

### For Basic Data Components

1. Create a new file in `components/`
2. Define a constructor function that returns a table
3. Add any methods the component needs

```lua
-- components/mycomponent.lua
local MyComponent = {}

function MyComponent.new(value)
    return {
        value = value or 0,
        -- Add methods if needed
        tostring = function(self)
            return string.format("MyComponent(%d)", self.value)
        end,
    }
end

return MyComponent
```

### For Entity Components

1. Create a basic component constructor
2. Create an `create_entity()` function that returns a complete entity with Object.new
3. Add `update(self, dt)` and `draw(self)` methods to the entity
4. Use `self.remove_me = true` to mark for removal

```lua
-- components/myentity.lua
local Object = require "core.object"
local Position = require "components.position"

local MyEntity = {}

function MyEntity.new(data)
    return { data = data }
end

function MyEntity.create_entity(x, y, z)
    local entity = Object.new {
        id = uuid(),
        priority = 50,
        position = Position.new(x, y, z),
        myentity = MyEntity.new("some data"),
    }
    
    function entity.update(self, dt)
        -- Update logic here
        if should_remove then
            self.remove_me = true
        end
    end
    
    function entity.draw(self)
        -- Draw logic here
        local camera_x, camera_y = G.camera:get_offset()
        -- ... render the entity
    end
    
    return entity
end

return MyEntity
```

## Benefits of This Architecture

1. **Mutualization**: Components are reused across multiple systems
2. **Separation of Concerns**: Systems coordinate, components execute
3. **Testability**: Components can be tested independently
4. **Maintainability**: Logic is localized to components
5. **Extensibility**: New components can be added without modifying systems
6. **Composition**: Entities are composed of multiple simple components

## Migration Notes

When converting existing systems to use components:

1. **Identify reusable data structures** → Create basic data components
2. **Extract entity logic** → Create entity components with update/draw
3. **Simplify systems** → Remove logic that's now in components
4. **Keep system coordination** → Systems still manage entity collections
5. **Use G for cross-system access** → Components can access other systems via G
