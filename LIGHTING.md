# Lighting System

The lighting system provides dynamic lighting for the Lasagna game world with shader-based rendering and light occlusion.

## About the Implementation

This system uses GLSL shaders to render realistic lighting with ray-traced occlusion, similar to games like Sandstorm/Sandustry. Key features:

- **Shader-based rendering**: GLSL shader computes lighting in real-time
- **Light occlusion**: Solid blocks cast shadows and block light
- **Ray-casting**: Samples along rays from lights to check for blocking
- **Player as light source**: Dynamic light that moves with the player

The approach differs from simple color multiplication by:
1. Rendering the world normally at full brightness
2. Generating an occlusion map (white = solid blocks)
3. Running a shader that ray-casts from each light source
4. Applying the resulting darkness overlay

## Features

- **Dynamic Lighting**: Blocks and entities are lit based on proximity to light sources
- **Player Light**: The player emits light, making them visible in dark areas
- **Day/Night Cycle Integration**: Ambient light changes with time of day
- **Per-Layer Lighting**: Each layer has independent lighting calculations
- **Smooth Falloff**: Light intensity decreases quadratically with distance for natural appearance

## Implementation

### Core Module: `lib/lighting.lua`

The Lighting module manages light sources, generates occlusion maps, and renders lighting via shaders.

#### Key Methods

- `load_shader()`: Loads the GLSL lighting shader
- `create_canvases(width, height)`: Creates render targets for occlusion map and lighting overlay
- `add_light(x, y, z, intensity, radius)`: Add a light source at the specified position
- `clear_lights()`: Remove all dynamic light sources (called each frame)
- `set_ambient_light(level)`: Set the base ambient light level (0.0-1.0)
- `generate_occlusion_map(world, ...)`: Creates a texture with solid blocks marked white
- `render_lighting_overlay(...)`: Runs the shader to compute lighting with occlusion
- `draw()`: Applies the lighting overlay to the screen

### Shader: `shaders/lighting.glsl`

The GLSL shader performs ray-traced lighting:

1. **Inputs**: Light positions, intensities, radii, ambient light, occlusion map
2. **Ray-casting**: For each pixel, traces rays from light sources to check for blocking
3. **Falloff**: Quadratic distance falloff `(1 - d/r)²`
4. **Occlusion**: Samples occlusion map along ray, reduces light if block found
5. **Output**: Black overlay with alpha = darkness level

The shader uses up to 32 simultaneous light sources and samples up to 64 points along each ray for occlusion detection.

### Integration

1. **World System** (`world/world.lua`):
   - Creates the Lighting instance with shader support
   - Updates ambient light based on weather/time
   - Adds player light source each frame
   - Generates occlusion map before rendering lighting
   - Renders lighting overlay after world layers

2. **Layer Rendering** (`world/layer.lua`):
   - Renders blocks at full brightness
   - Lighting applied as post-process via shader

3. **Entity Rendering** (`entities/drop.lua`, `entities/player.lua`):
   - Rendered at full brightness
   - Lighting applied via shader overlay

4. **Game** (`game.lua`):
   - Draws lighting overlay after player but before HUD
   - Recreates canvases on window resize

## Ambient Light Schedule

The ambient light level varies throughout the day:

- **Day (7:00-17:00)**: Full brightness (1.0)
- **Sunrise (5:00-7:00)**: Gradual increase from 0.15 to 1.0
- **Sunset (17:00-19:00)**: Gradual decrease from 1.0 to 0.15
- **Night (19:00-5:00)**: Low ambient light (0.15)

## Player Light Source

The player is configured as a light source with:
- **Intensity**: 0.9 (90% brightness)
- **Radius**: 12 blocks
- **Position**: Center of player entity
- **Dynamic**: Moves with the player
- **Occlusion**: Blocked by solid terrain blocks

## Light Calculation

The shader computes lighting for each pixel:

1. Start with ambient light level
2. For each light source on the same layer:
   - Calculate distance from light source
   - If within radius, calculate quadratic falloff: `(1 - distance/radius)²`
   - **Ray-cast occlusion**: Sample occlusion map along ray from light to pixel
   - If solid block found, reduce light based on distance past the block
   - Multiply by light intensity
   - Take maximum of current light level and this contribution
3. Invert to get darkness level
4. Render as black overlay with darkness alpha

### Occlusion Ray-Casting

For each pixel being lit:
- Cast a ray from the light source to the pixel
- Sample every ~4 pixels along the ray
- Check the occlusion map (white = solid block)
- If a block is found, light is reduced based on how far past the block we are
- This creates realistic shadows where blocks cast darkness

The quadratic falloff provides smooth, natural-looking light transitions, and the occlusion system creates dynamic shadows as the player moves through the world.

## Future Enhancements

Potential improvements to the lighting system:

- **Multiple light sources**: Torches, lanterns, or other light-emitting blocks
- **Light-emitting ores**: Glowing resources in caves
- **Colored lights**: Support for different light colors (RGB)
- **Soft shadows**: Smoother shadow edges with more samples
- **Dynamic lights**: Flickering torches, pulsing effects
- **Light through translucent blocks**: Partial occlusion for glass, water
- **Performance optimization**: Spatial indexing, lower sample counts for distant lights
- **Light persistence**: Static lights that don't need to be regenerated each frame

## Usage Example

To add a custom light source in game code:

```lua
-- Add a torch at position (10, 5) on layer 0
G.world.lighting:add_light(10, 5, 0, 1.0, 8)
```

Note: Dynamic lights are cleared each frame, so persistent lights need to be re-added in the update loop.

## Testing the Lighting System

To test the shader-based lighting system in-game:

1. **Run the game**: `love .`
2. **Enable debug mode**: Press `Backspace` to toggle debug overlay
3. **Observe the player light**:
   - The player emits light in a 12-block radius
   - Light is blocked by solid terrain (creates shadows)
   - In debug mode, a yellow circle shows the light radius
   - Debug overlay shows "Shader: enabled" if shader loaded successfully
4. **Test day/night cycle**:
   - Wait for time to change (or modify `C.DAY_DURATION` in constants.lua for faster testing)
   - At night (19:00-5:00), ambient light drops to 0.15
   - The player's light becomes much more visible in darkness
   - Shadows are visible where blocks occlude the player's light
5. **Test light occlusion**:
   - Move player near walls or terrain
   - Observe shadows cast by blocks
   - Light doesn't "bleed through" solid blocks
6. **Check lighting info**:
   - Debug overlay shows ambient light level
   - Shows if shader is enabled or disabled

### What to Look For

- **Darkness overlay**: Everything should darken at night
- **Player light bubble**: Bright area around player
- **Dynamic shadows**: Blocks create dark areas behind them
- **Smooth gradients**: Light fades smoothly from center
- **No light bleeding**: Light blocked by solid blocks
- **Performance**: Should run smoothly (shader is optimized)

### Quick Night Testing

To quickly test night lighting, modify `constants.lua`:

```lua
DAY_DURATION = 5,    -- seconds (very short day)
NIGHT_DURATION = 30, -- seconds
```

Or start the game at night by modifying `world/weather.lua` line 20:

```lua
self.time = C.NIGHT_DURATION / 2  -- Start at midnight
```

### Troubleshooting

If the shader doesn't load:
- Check console for "Lighting shader loaded successfully" or error messages
- Ensure `shaders/lighting.glsl` exists
- Debug mode will show "Shader: disabled" if it failed to load
- Game will fall back to rendering without lighting effects

If lighting looks wrong:
- Check that occlusion map is being generated
- Verify light positions are in correct coordinate space
- Ensure canvases are created at the right size
