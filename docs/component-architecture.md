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

- **Priority 10**: Physics component (gravity application)
- **Priority 15**: Physics system (collision detection and physics coordination)
- **Priority 20**: Velocity (position updates)
- **Priority 30**: Bullet, Drop (lifetime, behavior)
- **Priority 50**: Health (regeneration, health bar UI)
- **Priority 51**: Stamina (regeneration, stamina bar UI)

## Component Types

### VectorComponent (Position and Velocity)

VectorComponent is used for both position and velocity vectors:
- **Position**: Uses `x`, `y`, `z` fields for world coordinates
- **Velocity**: Uses `x`, `y` fields for horizontal and vertical velocity (z not used)

```lua
-- Position vector
position = VectorComponent.new(world_x, world_y, layer)

-- Velocity vector
velocity = VectorComponent.new()  -- x=0, y=0
velocity.x = 100  -- horizontal velocity
velocity.y = -50  -- vertical velocity (negative = upward)
```

### State Components (Data-only)

Some components are pure data containers without update/draw logic:
- Layer: Current layer information
- Inventory: Item storage

### Behavior Components (Update Logic)

Components with update() methods that modify entity state:
- **Health**: Health regeneration over time
- **Stamina**: Stamina regeneration over time
- **Physics**: Applies gravity to velocity (modifies velocity.y)
- **Velocity (VectorComponent)**: Applies velocity to position
- **Bullet (ProjectileComponent)**: Lifetime countdown and death marking
- **Drop (ItemDropComponent)**: Pickup delay and lifetime countdown

### Systems with Physics Logic

The physics system (`systems/physics.lua`) provides centralized collision detection and physics coordination:
- **check_collision**: AABB collision with world blocks
- **is_on_ground**: Check if entity is on solid ground
- **can_stand_up**: Check clearance for standing
- **apply_gravity**: Apply gravity to velocity
- **apply_horizontal_movement**: Horizontal movement with wall collision
- **apply_vertical_movement**: Vertical movement with floor/ceiling collision
- **clamp_to_world**: Prevent falling through world bounds

### Entity Rendering

Entities handle their own rendering directly:
- **Player**: Uses width, height, and color properties directly for rendering
- **Health**: Health bar UI rendering (positioned above hotbar)
- **Stamina**: Stamina bar UI rendering (positioned above hotbar)
- **Bullet**: Custom bullet rendering
- **Drop**: Block-based drop rendering with borders

#### UI Component Rendering

Health and Stamina components demonstrate self-contained UI rendering:

```lua
function Health.draw(self, entity)
    if not self.enabled then return end
    if not self.max or self.max <= 0 then return end
    
    -- Access entity.inventory for positioning
    if not entity or not entity.inventory then return end
    
    -- Calculate position relative to hotbar
    local screen_width, screen_height = love.graphics.getDimensions()
    local inv = entity.inventory
    local hotbar_x = (screen_width - (inv.hotbar_size * 60)) / 2
    
    -- Draw health bar UI
    -- (green/yellow/red based on percentage)
end
```

This pattern keeps UI rendering logic with the data it displays, while still allowing access to other entity components for positioning context.

## Entity Composition

### Simple Entities (Full Component-based)

Bullets and drops are managed by the unified EntitySystem and use full component-based updates:

```lua
-- Entity creation via EntitySystem
local drop = G.entity:newDrop(x, y, layer, block_id, count)
local bullet = G.entity:newBullet(x, y, layer, vx, vy, width, height, color, gravity, destroys_blocks)

-- Internally, entities are composed of:
local entity = {
    type = EntitySystem.TYPE_DROP,  -- or TYPE_BULLET
    position = VectorComponent.new(x, y, layer),
    velocity = VectorComponent.new(),  -- x/y velocity fields
    physics = PhysicsComponent.new(gravity, friction),
    drop = ItemDropComponent.new(block_id, count, lifetime, pickup_delay),
    -- or: bullet = ProjectileComponent.new(damage, lifetime, width, height, color, destroys_blocks),
    width = BLOCK_SIZE / 2,
    height = BLOCK_SIZE / 2,
}

-- In system update:
Object.update(entity, dt)  -- Recursively calls all component updates
EntitySystem:update_entity_physics(entity, dt)  -- Shared physics handling

-- In system draw:
entity.drop:draw(entity, camera_x, camera_y)
-- or: entity.bullet:draw(entity, camera_x, camera_y)
```

### Complex Entities (Selective Component Usage)

Player uses selective component updates and delegates physics to the physics system:

```lua
-- In PlayerSystem.load:
self.velocity.enabled = false  -- Disable automatic velocity application
self.physics.enabled = false   -- Disable automatic physics (handled by physics system)
self.width = BLOCK_SIZE        -- Player dimensions for collision and rendering
self.height = BLOCK_SIZE * 2
self.color = { 1, 1, 1, 1 }    -- Rendering color

-- In PlayerSystem.update:
Object.update(self, dt)  -- Still calls stamina/health regen
-- Physics system handles collision detection and physics:
PhysicsSystem.apply_gravity(vel, phys.gravity, dt)
PhysicsSystem.apply_horizontal_movement(G.world, pos, vel, self.width, self.height, dt)
PhysicsSystem.apply_vertical_movement(G.world, pos, vel, self.width, self.height, modifier, dt)
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

### Example: EntitySystem

The EntitySystem is a unified system that manages all non-player entities (drops, bullets, etc.).
It replaces the separate DropSystem and BulletSystem with shared entity management logic.

```lua
function EntitySystem.update(self, dt)
    for i = #self.entities, 1, -1 do
        local ent = self.entities[i]

        -- Component updates (physics, velocity, type-specific lifetime)
        Object.update(ent, dt)

        -- Physics-based collision using PhysicsSystem utilities
        self:update_entity_physics(ent, dt)

        -- Type-specific coordination
        if ent.type == EntitySystem.TYPE_DROP then
            -- Handle drop pickup and merging
        elseif ent.type == EntitySystem.TYPE_BULLET then
            -- Handle bullet collision and block destruction
        end
    end
end
```

Entities are created with a type field that determines their behavior:
- `EntitySystem.TYPE_DROP`: Item drops with pickup and merging logic
- `EntitySystem.TYPE_BULLET`: Projectiles with block collision and destruction

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
