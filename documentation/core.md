# Core Modules

The `core/` directory contains the foundational modules of Lasagna.

## init.lua

Initializes the core environment:
- Loads `libraries/luax` extensions
- Provides `DEBUG(level)` macro for printing caller info

```lua
require "core"  -- Load in main.lua
DEBUG()         -- Print current file:line function()
```

## object.lua

The composition system that powers Lasagna's architecture. See [architecture.md](architecture.md) for high-level overview.

### Object.new(table)

Creates a new Object with lifecycle methods:

```lua
local MySystem = Object.new {
    id = "mysystem",
    priority = 50,
}
```

### Lifecycle Methods

All methods receive `self` as first parameter. `update` and `draw` also pass `self` to sub-objects as the parent entity.

| Method | Signature | Description |
|--------|-----------|-------------|
| `load` | `(self, ...)` | Initialization |
| `update` | `(self, dt)` | Game logic |
| `draw` | `(self)` | Rendering |
| `keypressed` | `(self, key)` | Key down |
| `keyreleased` | `(self, key)` | Key up |
| `mousepressed` | `(self, x, y, button)` | Mouse down |
| `mousereleased` | `(self, x, y, button)` | Mouse up |
| `mousemoved` | `(self, x, y, dx, dy)` | Mouse move |
| `wheelmoved` | `(self, x, y)` | Scroll |
| `textinput` | `(self, text)` | Text input |
| `resize` | `(self, w, h)` | Window resize |
| `focus` | `(self, focused)` | Focus change |
| `quit` | `(self)` | Exit |

### Internal Behavior

```lua
-- Object_call collects all table properties, sorts by priority, calls method
local function Object_call(self, name, ...)
    -- Cache sorted sub-objects in self.__objects
    for _, object in ipairs(self.__objects) do
        local f = object[name]
        if type(f) == "function" then
            f(object, ...)
        end
    end
end
```

## game.lua

The Game object, assigned to global `G` in `main.lua`:

```lua
local Game = {
    priority = 0,
    state = GameStateComponent.new(GameStateComponent.BOOT),
    time = TimeComponent.new(1),
    world = require("systems.world"),
    control = require("systems.control"),
    camera = require("systems.camera"),
    player = require("systems.player"),
    mining = require("systems.mining"),
    building = require("systems.building"),
    weapon = require("systems.weapon"),
    entity = require("systems.entity"),
    ui = require("systems.interface"),
    chat = require("systems.chat"),
    lore = require("systems.lore"),
    debug = require("systems.debug"),
}
```

### Methods

| Method | Description |
|--------|-------------|
| `switch(gamestate)` | Change game state |
| `load(seed, debug)` | Initialize game |
| `reload()` | Reload world with same seed |

### Game States

Defined in `components/gamestate.lua`:
- `BOOT` - Initial state
- `LOAD` - Loading
- `PLAY` - Playing
- `QUIT` - Exiting

## noise.lua

Perlin noise implementation for terrain generation.

### Functions

| Function | Description |
|----------|-------------|
| `noise.perlin1d(x)` | 1D noise |
| `noise.perlin2d(x, y)` | 2D noise |
| `noise.perlin3d(x, y, z)` | 3D noise |
| `noise.octave_perlin2d(x, y, octaves, persistence, lacunarity)` | Fractal noise |
| `noise.seed(seed_or_rng)` | Seed the noise generator |

### Usage

```lua
local noise = require "core.noise"

noise.seed(12345)

-- Get terrain height
local height = noise.octave_perlin2d(x * 0.02, 0, 4, 0.5, 2.0)

-- Get 3D cave noise
local cave = noise.perlin3d(x * 0.1, y * 0.1, z * 0.1)
```

## generator.lua

Terrain generation pipeline using Perlin noise.

### Pipeline

1. **`calculate_surface_height`** - Surface height from noise
2. **`Generator.fill`** - Fill with air/stone
3. **`Generator.dirt_and_grass`** - Add surface layers
4. **`Generator.ore_veins`** - Generate ore deposits

### Usage

```lua
local generate = require "core.generator"

-- Called by WorldSystem for each column
generate(column_data, world_col, layer, world_height)
```

### Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `SURFACE_HEIGHT_RATIO` | 0.75 | Base surface at 75% height |
| `BASE_FREQUENCY` | 0.02 | Noise frequency |
| `BASE_AMPLITUDE` | 15 | Height variation |
| `DIRT_MIN_DEPTH` | 5 | Minimum dirt layer |
| `DIRT_MAX_DEPTH` | 15 | Maximum dirt layer |

### Ore Generation

Ores are registered in `registries/blocks.lua` with `ore_gen` properties:
- `frequency` - Noise frequency
- `threshold` - Noise threshold for placement
- `min_depth` / `max_depth` - Depth range
- `offset` - Noise offset (for variety)
