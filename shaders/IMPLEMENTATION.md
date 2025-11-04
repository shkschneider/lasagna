# GLSL Lighting Shader - Implementation Overview

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Game Loop                            │
│  (main.lua → game.lua → world.lua → layer.lua)            │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
         ┌───────────────────────────────┐
         │    Layer:draw() Method        │
         │   (world/layer.lua)           │
         └───────────────┬───────────────┘
                         │
          ┌──────────────┴──────────────┐
          │                             │
          ▼                             ▼
┌──────────────────┐         ┌──────────────────┐
│  Block Canvas    │         │  Layer Canvas    │
│  (Solidity Map)  │         │  (Visual Layer)  │
└─────────┬────────┘         └─────────┬────────┘
          │                             │
          │    ┌───────────────────┐    │
          └────►  Lighting Shader  ◄────┘
               │ (lighting.frag)   │
               └─────────┬─────────┘
                         │
                         ▼
               ┌──────────────────┐
               │  Final Output    │
               │  (Screen)        │
               └──────────────────┘
```

## Data Flow

### 1. Block Solidity Canvas
```lua
-- Render solid blocks as white pixels (alpha = 1.0)
for each visible block:
    if block is solid:
        draw white rectangle to blockCanvas
```

### 2. Layer Rendering
```lua
-- Render the actual colored blocks
for each visible block:
    if block exists:
        draw block with its color to layerCanvas
```

### 3. Shader Application
```lua
-- Pass data to shader
shader:send("lightPos", player_screen_position)
shader:send("blockTexture", blockCanvas)
shader:send(...) -- other parameters

-- Draw layer with shader applied
setShader(lightingShader)
draw(layerCanvas)
```

### 4. Shader Processing (GLSL)
For each pixel on screen:
```glsl
1. Calculate distance to light source (player)
2. If beyond light radius → apply ambient light only
3. Cast ray from light to pixel
4. For each step along the ray:
   - Sample blockTexture
   - If solid block found → pixel is in shadow
5. Calculate light intensity with falloff
6. Apply final lighting to pixel color
```

## Raycasting Algorithm

```
Player (Light Source)
    *
    |\
    | \    ray
    |  \
    |   \
    |    \
    |     ◄─── step
    |      \
    █       \   ← solid block detected
              \
               ● ← fragment (in shadow)
```

The shader casts a ray from the player to each pixel:
- **Step Size**: 8 pixels (configurable)
- **Max Steps**: distance / stepSize
- **Shadow Detection**: If ray hits solid block → shadow
- **Result**: Boolean (lit or shadowed)

## Light Falloff

```
Intensity
   1.0 ┤     ●●●●
       │    ●     ●
       │   ●       ●
   0.5 ┤  ●         ●
       │ ●           ●
       │●             ●
   0.3 ┼────────────────●─────► Distance
       0            RADIUS

Formula: intensity = ambient + (1-ambient) * (1 - d/r)²
```

- **Close to player**: Full brightness
- **At radius edge**: Ambient brightness
- **Beyond radius**: Ambient only
- **In shadow**: Ambient only

## Performance Optimizations

1. **Layer Selection**: Only applies to player's current layer
2. **Canvas Reuse**: Canvases created once, reused each frame
3. **Configurable Step Size**: Balance accuracy vs speed
4. **Early Exit**: Pixels beyond radius skip raycasting

## Memory Layout

```
Screen (1280x720)
├─ Layer Canvas (1280x720 RGBA)
│  └─ Visual representation of blocks
│
└─ Block Canvas (1280x720 RGBA)
   └─ Binary solidity map (alpha channel)
      0 = air, 1 = solid
```

## Shader Uniforms

| Uniform | Type | Purpose | Default |
|---------|------|---------|---------|
| lightPos | vec2 | Player position in screen coords | Dynamic |
| screenSize | vec2 | Window dimensions | Dynamic |
| lightRadius | float | Light radius in pixels | 400 |
| ambientLight | float | Base light level (0-1) | 0.3 |
| raycastStepSize | float | Ray step size in pixels | 8 |
| blockTexture | sampler2D | Solidity map | blockCanvas |

## Code Locations

- **Shader Loading**: `world/layer.lua:16-25`
- **Canvas Creation**: `world/layer.lua:95-100`
- **Block Canvas Rendering**: `world/layer.lua:103-126`
- **Layer Canvas Rendering**: `world/layer.lua:128-160`
- **Shader Application**: `world/layer.lua:162-182`
- **Shader Logic**: `shaders/lighting.frag`
- **Configuration**: `constants.lua:39-42`

## Extending the System

### Add More Light Sources
```lua
-- In shader, accept array of light positions
uniform vec2 lightPos[MAX_LIGHTS];
uniform int numLights;

-- In shader logic, check all lights
for (int i = 0; i < numLights; i++) {
    if (isLit(lightPos[i], screen_coords, screenSize)) {
        // Add light contribution
    }
}
```

### Add Colored Lights
```lua
-- Add light color uniform
uniform vec3 lightColor;

-- In shader, multiply by light color
return pixel * vec4(vec3(finalLight) * lightColor, 1.0);
```

### Dynamic Ambient Light (Day/Night)
```lua
-- In Lua, vary ambient based on time
local ambient = 0.8 - 0.5 * nightFactor
shader:send("ambientLight", ambient)
```

## Debugging Tips

1. **Visualize Block Canvas**:
   ```lua
   -- After rendering blockCanvas
   love.graphics.setCanvas()
   love.graphics.draw(blockCanvas, 0, 0)  -- See what shader sees
   ```

2. **Test Without Raycasting**:
   ```glsl
   // In shader, temporarily return early
   bool lit = true;  // Force all lit
   ```

3. **Visualize Ray Steps**:
   ```glsl
   // Color pixels based on number of steps
   return vec4(float(maxSteps) / 100.0, 0, 0, 1);
   ```

4. **Check Uniform Values**:
   ```lua
   -- Print shader uniforms
   print("lightPos:", playerScreenX, playerScreenY)
   print("radius:", C.LIGHT_RADIUS)
   ```
