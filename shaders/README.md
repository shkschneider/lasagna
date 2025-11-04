# Lighting Shader

This directory contains GLSL shaders for the Lasagna game's lighting system.

## Overview

The lighting system implements 2D dynamic lighting with raycasted shadows, using the player as a light source. The implementation is based on the technique described in [this blog post](https://icuwanl.wordpress.com/2018/07/05/light-sources-shadows-part-2/).

## Files

- `lighting.frag` - Fragment shader that implements lighting and shadow casting

## How It Works

1. **Light Source**: The player's position acts as a dynamic light source
2. **Raycasting**: For each pixel, rays are cast from the light source to determine if the path is obstructed by solid blocks
3. **Shadows**: If a ray hits a solid block before reaching the pixel, that pixel is rendered in shadow (ambient light only)
4. **Light Falloff**: Light intensity decreases quadratically with distance from the player
5. **Ambient Light**: A base level of light is always present (configurable via `C.AMBIENT_LIGHT`)

## Configuration

Lighting parameters can be adjusted in `constants.lua`:

- `LIGHT_RADIUS` (default: 400 pixels) - The radius of light around the player
- `AMBIENT_LIGHT` (default: 0.3) - Base light level in dark areas (0.0 = pitch black, 1.0 = full brightness)
- `RAYCAST_STEP_SIZE` (default: 8 pixels) - Step size for raymarching
  - Lower values = more accurate shadows but slower performance
  - Higher values = faster but less accurate shadows

## Performance Considerations

The shader is only applied to the player's current layer to maintain good performance. Background and foreground layers use simpler alpha-based rendering.

The raycasting algorithm uses a fixed step size to balance accuracy and performance. On lower-end hardware, you can increase `RAYCAST_STEP_SIZE` to improve framerate.

## Integration

The shader is automatically loaded when a layer is created (see `world/layer.lua`). If the shader fails to load, the game will fall back to rendering without lighting effects and log a warning.

The shader receives the following data:
- Player position (in screen coordinates)
- Screen dimensions
- Block solidity data (rendered to a separate texture)
- Lighting parameters from constants

## Troubleshooting

If lighting doesn't appear:
1. Check the console/logs for shader compilation errors
2. Ensure your GPU supports GLSL shaders (most modern GPUs do)
3. Verify that the `shaders/` directory exists and contains `lighting.frag`
4. Try disabling the shader by setting `Layer.lightingShader = nil` in `world/layer.lua` to verify the game runs without it
