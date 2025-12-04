# Age-Gated Crafting System

## Overview
The crafting system implements age progression that requires collecting materials before advancing to the next tier.

## Ages
- Age 0: Stone Age (starting age)
- Age 1: Bronze Age (requires 9 copper ore)
- Age 2: Iron Age (requires 9 iron ore)
- Age 3: Steel Age (requires 9 coal)
- Age 4: Flux Age (disabled for now - will require cobalt ore)

## Components

### 1. Tick System (`/src/game/tick.lua`)
- Throttles expensive operations to run only every N ticks
- 1 tick = 0.1 seconds (1/10th of a second)
- Used for checking crafting requirements every 10 ticks (1 second)

### 2. Recipe System (`/data/recipes/`)
- `init.lua`: Main recipe registry with helper functions
- `ages.lua`: Age upgrade recipes defining required materials
- Recipe structure: `{age = N, inputs = {...}, outputs = {...}}`

### 3. Crafting UI (`/src/ui/craft.lua`)
- Displays current age, next age, and required materials
- Shows material counts (owned/required) with color coding
- Craft button is disabled when requirements are not met
- Uses tick system for performance (checks every 10 ticks)

## Usage

1. Open inventory (default: E or I key)
2. Crafting UI appears on the right side
3. Collect required materials shown in the UI
4. Click "UPGRADE AGE" when materials are available
5. Materials are consumed and omnitool tier increases

## Testing

The tick system includes tests in `/tests/tick.lua` that can be run with:
```
lua5.1 tests/tick.lua
```

## Notes

- The old debug UPGRADE button still works for testing
- Materials are consumed from both hotbar and backpack
- Crafting state is cached and updated every 10 ticks for performance
