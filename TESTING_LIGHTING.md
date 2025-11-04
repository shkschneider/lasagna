# Testing Guide: GLSL Lighting Shader

This guide explains how to test the new lighting shader feature.

## Prerequisites

- LÖVE 2D framework installed (version 11.x recommended)
- The game should run without errors

## Testing Steps

### 1. Basic Functionality Test

Run the game normally:
```bash
love .
```

**Expected behavior:**
- The game should start without errors
- The player's current layer should have dynamic lighting
- The player acts as a light source with a visible radius
- Areas further from the player should be darker
- Background/foreground layers should render normally (no lighting)

### 2. Visual Verification

When the game is running, verify:

1. **Light Radius**: There should be a bright area around the player (approximately 400 pixels)
2. **Shadow Casting**: Solid blocks should cast shadows
   - Place blocks between you and an area - the area behind should be darker
   - Remove blocks - the area should become brighter
3. **Light Falloff**: Light intensity should decrease smoothly with distance
4. **Ambient Light**: Even the darkest areas should still be somewhat visible (30% brightness)

### 3. Test Shadow Casting

1. Move around the world and observe shadows
2. Place blocks in different configurations:
   - Single blocks
   - Walls (vertical lines of blocks)
   - Rooms (enclosed spaces)
3. Enter a room - inside should be darker with light only near entrances
4. Create a tunnel and move through it - light should follow you

### 4. Test Layer Switching

1. Press `Q` to switch to layer -1 (background)
   - **Expected**: No lighting shader (regular rendering)
2. Press `E` to return to layer 0
   - **Expected**: Lighting shader active again
3. Press `E` again to go to layer 1 (foreground)
   - **Expected**: No lighting shader (regular rendering)

### 5. Performance Testing

Monitor the game's frame rate:
- The game should run smoothly (ideally 60 FPS)
- If performance is poor, try adjusting parameters in `constants.lua`:
  - Increase `RAYCAST_STEP_SIZE` (try 12 or 16)
  - Decrease `LIGHT_RADIUS` (try 300 or 250)

### 6. Debug Mode Testing

Enable debug mode:
```bash
DEBUG=true love .
```

Or press `Backspace` while in-game to toggle debug mode.

**Expected behavior:**
- Console should show "Lighting shader loaded successfully" message
- No shader-related errors should appear
- Debug overlay should work normally

### 7. Fallback Testing

To test that the game works without the shader (fallback mode):

1. Temporarily rename the shader file:
   ```bash
   mv shaders/lighting.frag shaders/lighting.frag.bak
   ```

2. Run the game:
   ```bash
   love .
   ```

3. **Expected behavior:**
   - Game should start normally
   - Console shows "Failed to load lighting shader" warning
   - Layers render without lighting (regular rendering)
   - No crashes or errors

4. Restore the shader:
   ```bash
   mv shaders/lighting.frag.bak shaders/lighting.frag
   ```

## Adjusting Parameters

Edit `constants.lua` to tune the lighting:

```lua
-- Larger radius = bigger light area
LIGHT_RADIUS = 400,

-- Higher value = brighter dark areas (0.0 to 1.0)
AMBIENT_LIGHT = 0.3,

-- Higher value = better performance, lower accuracy
RAYCAST_STEP_SIZE = 8,
```

After changing parameters, restart the game to see the effects.

## Expected Visual Examples

### Outdoor Scene
- Bright area around player
- Smooth light falloff
- Terrain blocks cast subtle shadows

### Cave/Tunnel
- Strong contrast between lit and dark areas
- Clear shadow edges where light is blocked
- Ambient light allows navigation in dark areas

### Room with Entrance
- Bright near the entrance where player stands
- Darker interior areas
- Shadows on walls opposite to player

## Troubleshooting

### No lighting effect visible
- Check console for "Lighting shader loaded successfully"
- Verify you're on layer 0 (the main layer)
- Try adjusting `LIGHT_RADIUS` to a larger value (e.g., 600)
- Ensure your GPU supports GLSL shaders

### Performance issues
- Increase `RAYCAST_STEP_SIZE` to 12 or 16
- Decrease `LIGHT_RADIUS` to 250 or 300
- Check if other applications are using GPU resources

### Shader won't load
- Verify `shaders/lighting.frag` exists
- Check file permissions (should be readable)
- Look for GLSL compilation errors in console

### Weird visual artifacts
- Try restarting the game
- Check if GPU drivers are up to date
- Verify constants are valid numbers (not nil or negative)

## Screenshots

When testing, it would be helpful to capture screenshots showing:
1. Before/after comparison (with shader vs without)
2. Shadow casting demonstration
3. Light falloff demonstration
4. Different lighting scenarios (open area, tunnel, room)

Use F12 or your OS screenshot tool to capture the game window.
