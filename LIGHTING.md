# Lighting System

The lighting system provides dynamic lighting for the Lasagna game world, including day/night cycles and light sources.

## About Bitumbra

The issue mentioned considering [@a13X-B/bitumbra](https://github.com/a13X-B/bitumbra) as a lighting library. However, this implementation uses a custom, lightweight lighting solution that:

- Integrates seamlessly with the existing codebase structure
- Is simple to understand and modify
- Has minimal performance overhead
- Doesn't require external dependencies

If more advanced lighting features are needed (such as shadows, light occlusion, or more complex light propagation), bitumbra could be evaluated as an alternative in the future.

## Features

- **Dynamic Lighting**: Blocks and entities are lit based on proximity to light sources
- **Player Light**: The player emits light, making them visible in dark areas
- **Day/Night Cycle Integration**: Ambient light changes with time of day
- **Per-Layer Lighting**: Each layer has independent lighting calculations
- **Smooth Falloff**: Light intensity decreases quadratically with distance for natural appearance

## Implementation

### Core Module: `lib/lighting.lua`

The Lighting module manages all light sources and calculates light levels at any position in the world.

#### Key Methods

- `add_light(x, y, z, intensity, radius)`: Add a light source at the specified position
- `clear_lights()`: Remove all dynamic light sources (called each frame)
- `set_ambient_light(level)`: Set the base ambient light level (0.0-1.0)
- `get_light_level(x, y, z)`: Calculate the total light level at a position

### Integration

1. **World System** (`world/world.lua`):
   - Creates the Lighting instance
   - Updates ambient light based on weather/time
   - Adds player light source each frame
   - Clears and rebuilds dynamic lights every frame

2. **Layer Rendering** (`world/layer.lua`):
   - Queries light level for each block before rendering
   - Multiplies block colors by light level for darkening effect

3. **Entity Rendering** (`entities/drop.lua`):
   - Dropped items respect lighting in their layer
   - Colors are multiplied by light level

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

## Light Calculation

Light level at any position is calculated as:

1. Start with ambient light level
2. For each light source on the same layer:
   - Calculate distance from light source
   - If within radius, calculate falloff: `(1 - distance/radius)²`
   - Multiply by light intensity
   - Take maximum of current light level and this contribution
3. Clamp result to [0.0, 1.0]

The quadratic falloff (`²`) provides smooth, natural-looking light transitions.

## Future Enhancements

Potential improvements to the lighting system:

- **Static Light Sources**: Torches, lanterns, or other light-emitting blocks
- **Light-Emitting Ores**: Glowing resources in caves
- **Colored Lights**: Support for different light colors
- **Light Blocking**: Shadows and occlusion
- **Smooth Lighting**: Interpolate light levels between blocks
- **Flickering Effects**: Animated light variations
- **Performance Optimization**: Spatial indexing for large numbers of lights

## Usage Example

To add a custom light source in game code:

```lua
-- Add a torch at position (10, 5) on layer 0
G.world.lighting:add_light(10, 5, 0, 1.0, 8)
```

Note: Dynamic lights are cleared each frame, so persistent lights need to be re-added in the update loop.

## Testing the Lighting System

To test the lighting system in-game:

1. **Run the game**: `love .`
2. **Enable debug mode**: Press `Backspace` to toggle debug overlay
3. **Observe the player light**:
   - The player emits light in a 12-block radius
   - In debug mode, a yellow circle shows the light radius
   - Blocks closer to the player are brighter
4. **Test day/night cycle**:
   - Wait for time to change (or modify `C.DAY_DURATION` in constants.lua for faster testing)
   - At night (19:00-5:00), ambient light drops to 0.15
   - The player's light becomes more prominent in darkness
5. **Check lighting info**:
   - Debug overlay shows current light level at mouse cursor
   - Shows ambient light level
6. **Visual effects**:
   - Player has a subtle glow at night
   - All blocks darken based on distance from light sources
   - Dropped items also respect lighting

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
