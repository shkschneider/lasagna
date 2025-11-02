# lasagna

> 2D procedurally-generated, layered sandbox building game built with Love2d (Lua).

- `main.lua`: love load() / update() / draw()
- `game.lua`: world ...
  - `world/`: layers entities ...
    - entities: player ...
    - layer: blocks ...
    - seasons: seasonal evolution of day/night cycles ...
    - weather: day/night cycle & sky colors ...
- `lib/object`: new() / load() / update() / draw()
- `lib/noise`: init() / perlin 1d/2d ...

## Features

### Seasons System
The game includes a dynamic seasons system that affects gameplay:
- **Four seasons**: Spring, Summer, Autumn, Winter
- **Day/night cycle variations**: Longer days in summer, shorter days in winter
- **Seasonal sky colors**: Each season has unique atmospheric tints
- **Automatic progression**: Seasons change every 5 minutes of gameplay

Each season has distinct characteristics:
- **Spring**: Balanced day/night, slight green tint
- **Summer**: Longer days (30% longer), shorter nights, brighter blue skies
- **Autumn**: Balanced day/night, warm orange tones
- **Winter**: Shorter days (30% shorter), longer nights, cool blue tint

## Run

```sh
love .

DEBUG=true love .

SEED=42 love .
```

_This toy project was created with the help of GitHub CoPilot as a test._
