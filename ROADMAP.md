# Roadmap — lasagna

This roadmap is organized as a sequence of small versions that incrementally build toward a playable MVP and beyond. Each version lists goals, non-goals, and clear acceptance criteria so you can check progress without getting bogged down in infrastructure (no CI / boards assumed).

Notes
- Engine: LÖVE 2D (Lua). Keep that for the prototype.
- Scope for MVP (v0.1): world generation, layers, mining/breaking, placing/building, inventory/omnitool, drops & pickup.
- Keep assets and polish minimal (placeholders) — focus on gameplay and correctness.

---

v0.3 — Death & snapshot restore
- Goals
  - Automatic periodic snapshot system saving world and player state (lightweight).
  - On death, restore the last snapshot (no manual saves).
- Non-goals
  - Long-term persistence and multi-snapshot UI management.
- Acceptance criteria
  - If player dies, the world and player inventory/position/health restore to the last snapshot slot.

---

v0.4 — World generation (part 2)

---

v0.5 — Crafting and Ages (basic progression)
- Goals
  - Hand crafting and Workbench recipes (simple recipes only).
  - Age progression system: unlocks (per README) — at minimum unlock an extra 9-slot row for inventory and next-tier Omnitool.
  - Implement one or two processing stations (e.g., furnace) as single-block machines for smelting.
  - Simple recipe UI and crafting results.
- Non-goals
  - Full machine automation, Flux, advanced multi-block machines.
- Acceptance criteria
  - Player can craft items by recipes.
  - Age advancement unlocks a storage row and the next Omnitool tier; UI reflects it.
  - Furnace processes items with a visible progress indicator.

---

v0.6 — Graphics (spritesheet, tiles...)

---

v0.7 — Enemies (deferred for MVP)
- Goals
  - Basic enemy types (passive/hostile), layer-aware spawn rules, simple pathing/aggro.
  - Health/damage system for player and enemies.
- Non-goals
  - Complex AI, groups, advanced behaviors.
- Acceptance criteria
  - Hostile enemies can spawn and damage the player; enemies obey layer restrictions for interaction.

---

v0.8 — UX, polish, and quality-of-life
- Goals
  - Inventory drag/drop, stack splitting, mouse-driven placement/dropping.
  - HUD polish (health, age indicator, tooltips).
  - Basic sound & placeholder art assets.
  - Performance instrumentation for worldgen and entity updates.
- Acceptance criteria
  - Usable inventory UX, basic SFX for pick/place/break, acceptable frame rate on target machine.

---

v1.0 — Feature complete prototype (scope-limited)
- Goals
  - All v0.x feature areas integrated and stable.
  - A minimal set of machines and automation primitives.
  - Save/load (beyond snapshots) and a simple options menu.
- Non-goals
  - Full polish or final art.
- Acceptance criteria
  - Playable experience with progression through at least a few Ages, crafting loop functional, and reasonable UX.

---

Future / beyond v1.0 (non-exhaustive)
- Machines & automation (multi-block, conveyors/tubes).
- Flux power network and performance scaling.
- Advanced world features (vertical biomes, special ruins).
- Multiplayer / server authoritative simulation (consider Go/raylib if this becomes core).
- Rich AI and enemy systems.
- Final art, audio, and release-quality polish.

---

Implementation notes & priorities
- Top priority for initial work: v0.1 plumbing. Stabilize prototypes, inventory shape, and default drop behavior before intensive feature work.
- Keep gameplay logic engine-agnostic where practical (small Engine Abstraction Layer helps future migration).
- Use placeholder assets and focus on deterministic, testable systems (seeded worldgen, canonical APIs).
- Break tasks into small PRs/commits by feature (e.g., world:get_block_proto; render manager; drop entity).
