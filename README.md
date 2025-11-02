# lasagna

> 2D procedurally-generated, layered sandbox building game built with Love2d (Lua).

- `main.lua`: love load() / update() / draw()
- `game.lua`: world ...
  - `world/`: layers entities ...
    - entities: player ...
    - layer: blocks ...
- `lib/object`: new() / load() / update() / draw()
- `lib/noise`: init() / perlin 1d/2d ...

## Run

```sh
love .

DEBUG=true love .

SEED=42 love .
```

## Roadmap

[X] WorldGen (horizontal)
[~] Layer-to-layer
[X] Blocks
[X] Player
[X] Hotbar
[~] Drops
[ ] WorldGen (vertical)
[ ] Ores & Stuff
[ ] Inventory

_This toy project was created with the help of GitHub CoPilot as a test._
