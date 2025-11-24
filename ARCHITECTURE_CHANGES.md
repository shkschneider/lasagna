# Architecture Changes Summary

## Overview
This PR implements a mutualized component architecture based on the core/object recursive composition pattern as requested in the issue.

## What Was Done

### 1. Created Components Directory (18 components)

#### Basic Data Components
- **position.lua**: 2D position with layer (x, y, z)
- **velocity.lua**: 2D velocity (vx, vy)
- **physics.lua**: Physics properties (gravity, friction)
- **collider.lua**: Collision bounds (width, height)
- **visual.lua**: Rendering properties (color, width, height)
- **layer.lua**: Layer management

#### Player Components
- **health.lua**: Health management
- **stamina.lua**: Stamina management
- **stance.lua**: Movement stance (standing, jumping, falling)
- **inventory.lua**: Item storage
- **omnitool.lua**: Tool progression

#### Game State Components
- **gamestate.lua**: Game state tracking
- **timescale.lua**: Time scaling and pause
- **worlddata.lua**: World generation data
- **camera.lua**: Camera positioning

#### Self-Contained Entity Components
- **bullet.lua**: Complete bullet entity with update/draw methods
- **drop.lua**: Complete drop entity with update/draw methods

### 2. Refactored Systems

#### BulletSystem (systems/bullet.lua)
- **Before**: 117 lines with all logic in system
- **After**: 42 lines, delegates to Bullet component
- Logic moved to Bullet component: physics, collision, lifetime, rendering

#### DropSystem (systems/drop.lua)
- **Before**: 166 lines with all logic in system
- **After**: 42 lines, delegates to Drop component
- Logic moved to Drop component: physics, collision, pickup, rendering

### 3. Bug Fixes
- Fixed Object.mousereleased missing self parameter in core/object.lua
- Fixed GameState tostring to be instance method

### 4. Documentation
- Created comprehensive architecture guide: docs/components.md
- Documents component types, usage patterns, and best practices

## Key Architectural Principles

1. **Components are self-contained**: Each component has its own data and behavior
2. **Systems coordinate**: Systems manage entity collections but delegate logic to components
3. **Global G access**: Components access other systems through global G object
4. **Entity lifecycle**: Entities use 'remove_me' flag for removal
5. **Recursive composition**: Entities are composed of multiple simple components

## Benefits

1. **Code Reuse**: Components are reused across multiple systems
2. **Maintainability**: Logic is localized, easier to find and modify
3. **Testability**: Components can be tested independently
4. **Extensibility**: New components/entities can be added without modifying systems
5. **Separation of Concerns**: Clear distinction between coordination and execution

## Before/After Example

### Before: Bullet Logic in System
```lua
function BulletSystem.update(self, dt)
    for i = #self.entities, 1, -1 do
        local ent = self.entities[i]
        -- 50+ lines of physics, collision, rendering logic
        ent.velocity.vy = ent.velocity.vy + ent.physics.gravity * dt
        ent.position.x = ent.position.x + ent.velocity.vx * dt
        -- ... more logic
    end
end
```

### After: Bullet Logic in Component
```lua
-- System just coordinates
function BulletSystem.update(self, dt)
    for i = #self.entities, 1, -1 do
        local ent = self.entities[i]
        Object.update(ent, dt)  -- Component handles everything
        if ent.remove_me then
            table.remove(self.entities, i)
        end
    end
end

-- Component manages itself
function entity.update(self, dt)
    -- Apply physics
    self.velocity.vy = self.velocity.vy + self.physics.gravity * dt
    self.position.x = self.position.x + self.velocity.vx * dt
    self.position.y = self.position.y + self.velocity.vy * dt
    -- Handle collision with G.world
    -- Manage lifetime
    -- Set self.remove_me when done
end
```

## Files Changed

- Created: 18 component files in components/
- Modified: systems/bullet.lua, systems/drop.lua, core/object.lua
- Added: docs/components.md

## Verification

- All Lua syntax verified with luac
- Code review passed with no issues
- All components follow consistent patterns
- Systems properly delegate to components
- Global G object accessible to all components

## Next Steps for Developers

When adding new entity types:
1. Create component in components/
2. Add create_entity() function with Object.new
3. Implement update(self, dt) and draw(self) in the entity
4. Use self.remove_me for lifecycle management
5. Access other systems through global G
6. Create corresponding system to manage the entity collection

See docs/components.md for detailed examples and patterns.
