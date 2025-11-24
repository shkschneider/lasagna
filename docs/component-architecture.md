# Component-based Update/Draw Architecture

## Overview

Lasagna uses a component-based architecture where game entities are composed of multiple components, each responsible for specific behavior or data. The Object system in `core/object.lua` provides recursive composition, automatically calling `update()` and `draw()` methods on all components based on priority ordering.

## Component Structure

### Base Component Pattern

Every component follows this structure:

```lua
local ComponentName = {}

function ComponentName.new(param1, param2, ...)
    local instance = {
        id = "component_name",
        priority = 50,  -- Controls update/draw order (lower = earlier)
        enabled = true,  -- Allow toggling at runtime
        -- Component-specific properties
    }
    
    -- Assign methods to instance
    instance.update = ComponentName.update
    instance.draw = ComponentName.draw
    
    return instance
end

-- Update method signature: (self, dt, entity)
function ComponentName.update(self, dt, entity)
    if not self.enabled then return end
    -- Component update logic here
end

-- Draw method signature: (self, entity, ...)
function ComponentName.draw(self, entity, ...)
    if not self.enabled then return end
    -- Component rendering logic here
end

return ComponentName
```

### Component Priorities

Components update/draw in priority order (lowest to highest):

- **Priority 10**: Physics (gravity application)
- **Priority 20**: Velocity (position updates)
- **Priority 30**: Bullet, Drop (lifetime, behavior)
- **Priority 50**: Health (regeneration)
- **Priority 51**: Stamina (regeneration)
- **Priority 100**: Visual (rendering)

## Component Types

### State Components (Data-only)

Some components are pure data containers without update/draw logic:
- Position: World coordinates (x, y, z)
- Collider: Collision box dimensions
- Layer: Current layer information
- Inventory: Item storage

### Behavior Components (Update Logic)

Components with update() methods that modify entity state:
- **Health**: Health regeneration over time
- **Stamina**: Stamina regeneration over time
- **Physics**: Applies gravity to velocity
- **Velocity**: Applies velocity to position
- **Bullet**: Lifetime countdown and death marking
- **Drop**: Pickup delay and lifetime countdown

### Visual Components (Draw Logic)

Components with draw() methods that render entities:
- **Visual**: Basic colored rectangle rendering
- **Bullet**: Custom bullet rendering
- **Drop**: Block-based drop rendering with borders

## Entity Composition

### Simple Entities (Full Component-based)

Bullets and drops use full component-based updates:

```lua
local bullet_entity = {
    position = Position.new(x, y, layer),
    velocity = Velocity.new(vx, vy),
    physics = Physics.new(gravity, friction),
    bullet = Bullet.new(damage, lifetime, width, height, color),
}

-- In system update:
Object.update(bullet_entity, dt)  -- Recursively calls all component updates

-- In system draw:
bullet_entity.bullet:draw(bullet_entity, camera_x, camera_y)
```

### Complex Entities (Selective Component Usage)

Player uses selective component updates due to complex collision:

```lua
-- In PlayerSystem.load:
self.velocity.enabled = false  -- Disable automatic velocity application
self.physics.enabled = false   -- Disable automatic physics
self.visual.enabled = false    -- Disable automatic visual rendering

-- In PlayerSystem.update:
Object.update(self, dt)  -- Still calls stamina/health regen
-- Manual physics and collision handling follows...
```

## System Architecture

### System Responsibilities

Systems are now **thin coordinators** that:
1. Manage entity collections
2. Call Object.update/draw on entities
3. Handle cross-entity interactions (collision, pickup, merging)
4. Coordinate with game state (world, player)

Systems do NOT:
- Implement per-entity physics (moved to components)
- Implement per-entity rendering (moved to components)
- Implement per-entity behavior (moved to components)

### Example: BulletSystem

```lua
function BulletSystem.update(self, dt)
    for i = #self.entities, 1, -1 do
        local ent = self.entities[i]

        -- Component updates (physics, velocity, bullet lifetime)
        Object.update(ent, dt)

        -- System coordination: collision detection
        local col, row = G.world:world_to_block(ent.position.x, ent.position.y)
        local block_def = G.world:get_block_def(ent.position.z, col, row)

        if block_def and block_def.solid then
            -- System coordination: handle collision effects
            -- (block destruction, drop spawning, etc.)
            table.remove(self.entities, i)
        elseif ent.bullet.dead then
            -- Remove if marked dead by component
            table.remove(self.entities, i)
        end
    end
end
```

## Object System

The Object system in `core/object.lua` provides recursive composition:

```lua
-- Object.update passes parent entity to components
function Object.update(self, dt)
    Object_call(self, "update", dt, self)
end

-- Object.draw passes parent entity to components
function Object.draw(self)
    Object_call(self, "draw", self)
end
```

### Automatic Component Discovery

Object_call automatically:
1. Discovers all table properties on an entity
2. Sorts them by priority
3. Calls the specified method on each component
4. Passes parent entity as parameter

## Debugging

### Enable/Disable Components

All components support runtime toggling:

```lua
entity.physics.enabled = false  -- Disable physics
entity.visual.enabled = false   -- Disable rendering
```

### Priority Ordering

Components update in priority order. To debug ordering:

```lua
-- Lower priority = earlier execution
component.priority = 5  -- Updates before priority 10
```

## Migration Notes

### From System to Component

When migrating logic from system to component:

1. **Identify per-entity logic**: Move to component update()
2. **Identify per-entity rendering**: Move to component draw()
3. **Keep cross-entity logic**: Leave in system (collision, pickup, etc.)
4. **Keep coordination logic**: Leave in system (entity creation/removal)

### Example Migration

Before (in system):
```lua
function DropSystem.update(self, dt)
    for _, ent in ipairs(self.entities) do
        ent.drop.lifetime = ent.drop.lifetime - dt
        if ent.drop.lifetime <= 0 then
            -- remove entity
        end
    end
end
```

After (in component):
```lua
function Drop.update(self, dt, entity)
    self.lifetime = self.lifetime - dt
    if self.lifetime <= 0 then
        self.dead = true  -- Mark for system removal
    end
end
```

After (in system):
```lua
function DropSystem.update(self, dt)
    for i = #self.entities, 1, -1 do
        local ent = self.entities[i]
        Object.update(ent, dt)  -- Component handles lifetime
        
        if ent.drop.dead then
            table.remove(self.entities, i)  -- System handles removal
        end
    end
end
```

## Testing

Component behavior can be tested independently:

```lua
-- Create component
local health = Health.new(50, 100)
health.regen_rate = 10

-- Test update
health:update(1, nil)
assert(health.current == 60)  -- 50 + 10*1

-- Test enable/disable
health.enabled = false
health:update(1, nil)
assert(health.current == 60)  -- No change when disabled
```

See `/tmp/test_components.lua` for comprehensive test suite.

## Best Practices

1. **Keep components focused**: One responsibility per component
2. **Use priorities wisely**: Physics before velocity, behavior before rendering
3. **Enable/disable for debugging**: Test components in isolation
4. **Test independently**: Components should be testable without full game
5. **Document dependencies**: Note if component requires other components
6. **Avoid tight coupling**: Use entity reference, not direct component access
7. **System coordination only**: Keep cross-entity logic in systems
8. **Component implementation only**: Keep per-entity logic in components

## Future Enhancements

Potential improvements to the component system:

- **Component messages**: Cross-component communication via event system
- **Component dependencies**: Declare required components
- **Hot reload**: Runtime component replacement for rapid iteration
- **Component profiling**: Track per-component performance
- **Component pooling**: Reuse component instances for performance
