# GitHub Copilot Instructions for Lasagna

## Project Overview

**Lasagna** is a 2D procedurally-generated, layered sandbox building game built with [LÖVE](https://love2d.org/) (Lua game framework).

Key characteristics:
- Written in Lua for the LÖVE 2D game engine
- Procedural terrain generation using Perlin noise
- Multi-layer world system (layers -1, 0, 1)
- Entity-component style architecture
- Physics-based player movement with collision detection

## Architecture

### Core Components

1. **main.lua**: Entry point interfacing with LÖVE APIs
   - Delegates to Game object for all game logic
   - Handles window setup, input events, and main loop

2. **game.lua**: Central game controller
   - Manages World and Player instances
   - Defines gameplay constants (gravity, movement speeds, etc.)
   - Handles camera, rendering, and UI coordination

3. **world/world.lua**: World simulation and terrain management
   - Procedural terrain generation per layer
   - Tile/block management
   - Entity registration and physics updates
   - Lazy generation of terrain as needed

4. **entities/player.lua**: Player entity and control
   - Movement, jumping, crouching mechanics
   - Block placement/breaking
   - Layer switching (parallax navigation)

5. **entities/movements.lua**: Shared movement physics
   - Gravity, acceleration, friction
   - Collision detection and response
   - Step-up mechanics

### Supporting Libraries

- **lib/object.lua**: Simple OOP system for Lua
- **lib/noise.lua**: Perlin noise implementation for terrain generation
- **lib/log.lua**: Logging utilities
- **lib/serpent.lua**: Data serialization (debugging)

### Block System

- **world/blocks.lua**: Block type definitions and properties
- **world/block.lua**: Individual block instances

## Coding Conventions

### Style Guidelines

- **Indentation**: 4 spaces (as per .editorconfig)
- **Line endings**: LF (Unix-style)
- **Charset**: UTF-8
- **Naming**:
  - `snake_case` for variables and functions
  - `PascalCase` for classes/objects
  - `SCREAMING_SNAKE_CASE` for constants

### Code Organization

- Use `local` keyword for all variables/functions unless global is required
- Require dependencies at the top of files
- Group related functionality together
- Constants defined at the top of class definitions

### Object System Usage

```lua
local Object = require("lib.object")

local MyClass = Object {
    CONSTANT = 42,
    default_value = 0,
}

function MyClass:new(param)
    self.value = param or self.default_value
end

function MyClass:method()
    -- implementation
end
```

## Key Patterns

### World Layers

The game uses a 3-layer parallax system:
- Layer -1: Background layer (slower parallax)
- Layer 0: Main gameplay layer
- Layer 1: Foreground layer (faster parallax)

Each layer has independent:
- Terrain height generation
- Amplitude and frequency parameters
- Tile grids
- Rendering canvases

### Coordinate System

- **World coordinates**: Block-based (integers)
- **Screen coordinates**: Pixels
- Conversion: `world_pos * BLOCK_SIZE = pixel_pos`
- Player position is in world coordinates (blocks)

### Terrain Generation

- Uses Perlin noise for organic terrain
- Lazy generation: columns generated as needed
- Each layer has configurable base height, amplitude, and frequency
- Terrain types: Air, Grass, Dirt, Stone

### Physics and Movement

- Grid-based collision detection
- Continuous collision response
- Support for:
  - Walking/running with acceleration
  - Jumping with variable height
  - Crouching with reduced speed
  - Step-up for 1-block obstacles
  - Air control (reduced)

## Development Workflow

### Running the Game

```bash
love .
```

### Debug Mode

```bash
DEBUG=true love .
```

Enables verbose logging for development.

### Custom Seed

```bash
SEED=12345 love .
```

Use a specific seed for reproducible terrain generation.

### Hot Reload

Press `Delete` key to reload the world with the current seed.

## Common Development Tasks

### Adding a New Block Type

1. Add definition to `world/blocks.lua`
2. Define properties (solid, color, textures)
3. Update generation logic in `world/world.lua` if needed

### Modifying Player Controls

1. Edit `entities/player.lua` for intent generation
2. Modify `entities/movements.lua` for physics changes
3. Update constants in `game.lua` for tuning

### Adjusting Terrain Generation

1. Modify layer parameters in `game.lua`:
   - `LAYER_BASE_HEIGHTS`: Starting height per layer
   - `AMPLITUDE`: Height variation range
   - `FREQUENCY`: Terrain smoothness (higher = smoother)

2. Adjust noise generation in `world/world.lua`

### Adding New Entities

1. Create new file in `entities/` directory
2. Use `Object` system for class definition
3. Implement required methods (update, draw)
4. Register with World entity system

## Performance Considerations

- Terrain is generated lazily (only visible/nearby columns)
- Each layer rendered to separate canvas for efficiency
- Entity updates use delta time for frame-rate independence
- Collision checks optimized for nearby tiles only

## Testing

Currently, this is a toy project without formal test infrastructure. Manual testing via running the game is the primary validation method.

When adding features:
- Test across multiple seeds
- Verify physics behavior (jumping, collision)
- Check layer transitions work correctly
- Ensure no crashes or Lua errors

## Dependencies

- LÖVE 2D game framework (version 11.x recommended)
- No external Lua libraries (all dependencies included in lib/)

## Future Development Ideas

- Save/load world state
- More block types and interactions
- Lighting system
- Multi-player support
- Inventory and crafting
- Better UI/HUD
- Sound effects and music

## Notes for Future Self

- This project was created as a test/learning project with GitHub Copilot
- Focus on keeping the codebase simple and readable
- The object system is minimal but effective for this scale
- Terrain generation can be CPU-intensive; optimize column generation if adding more complexity
- Player movement uses intent-based design: player generates intents, world applies physics
- Camera follows player with smooth tracking

## Useful Commands

```bash
# Run game
love .

# Debug mode
DEBUG=true love .

# Specific seed
SEED=42 love .

# Check Lua syntax
luac -p *.lua
```

## When in Doubt

- Check existing patterns in similar files
- Keep changes minimal and focused
- Test immediately after changes
- Use debug mode to understand behavior
- Reference LÖVE documentation: https://love2d.org/wiki/
