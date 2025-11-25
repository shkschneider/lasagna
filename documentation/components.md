# Components

Components are data containers in `components/` with optional behavior.

## Overview

| Component | Purpose |
|-----------|---------|
| `vector` | Position (x, y, z) or velocity (vx, vy) |
| `stack` | Item stack (id + count, max 64) |
| `health` | Health with regen and UI |
| `stamina` | Stamina with regen and UI |
| `projectile` | Bullet properties |
| `itemdrop` | Drop properties |
| `time` | Game time scale/pause |
| `gamestate` | Game state machine |
| `omnitool` | Mining tool tier |
| `stance` | Player stance (standing/crouching) |
| `camera` | Camera offset |
| `keyboard` | Key state tracking |
| `mouse` | Mouse state tracking |
| `worlddata` | World metadata |

## Key Components

### VectorComponent (`vector.lua`)

Position or velocity vector:
```lua
local pos = VectorComponent.new(x, y, z)
pos.x, pos.y, pos.z  -- Coordinates
pos.enabled          -- Auto-update flag
```

When used as velocity, applies to position in `update()`.

### StackComponent (`stack.lua`)

Item stack (max 64):
```lua
local stack = StackComponent.new(id, count, "block"|"item")
stack.block_id / stack.item_id  -- Item identifier
stack.count                      -- Stack size
stack:can_add(n)                 -- Check space
stack:add(n) / :remove(n)        -- Modify count
stack:can_merge(other)           -- Same type check
stack:split(n) / :clone()        -- Create copies
```

### HealthComponent (`health.lua`)

Health with UI:
```lua
local hp = HealthComponent.new(current, max, regen_rate)
hp:damage(amount)   -- Take damage
hp:heal(amount)     -- Restore health
hp:is_dead()        -- Check if dead
```

### StaminaComponent (`stamina.lua`)

Stamina with UI:
```lua
local stam = StaminaComponent.new(current, max, regen_rate)
stam:use(amount)    -- Consume stamina
stam:has(amount)    -- Check available
```

### ProjectileComponent (`projectile.lua`)

Bullet properties:
```lua
local bullet = ProjectileComponent.new(damage, lifetime, width, height, color, destroys_blocks)
```

### ItemDropComponent (`itemdrop.lua`)

Drop properties:
```lua
local drop = ItemDropComponent.new(block_id, count, lifetime, pickup_delay)
```

## Component Pattern

Components should:
1. Assign `update`/`draw` to instances in `new()`
2. Use `priority` for update order
3. Check `enabled` flag before updating
4. Receive parent entity as second param in `update(self, dt, entity)`

```lua
function MyComponent.new()
    local instance = {
        priority = 50,
        enabled = true,
    }
    instance.update = MyComponent.update
    return instance
end

function MyComponent.update(self, dt, entity)
    if not self.enabled then return end
    -- Logic here
end
```
