# Roadmap — lasagna

This roadmap is organized as a sequence of small versions that incrementally build toward a playable MVP and beyond. Each version lists goals, non-goals, and clear acceptance criteria so you can check progress without getting bogged down in infrastructure (no CI / boards assumed).

Notes
- Engine: LÖVE 2D (Lua). Keep that for the prototype.
- Scope for MVP (v0.1): world generation, layers, mining/breaking, placing/building, inventory/omnitool, drops & pickup.
- Keep assets and polish minimal (placeholders) — focus on gameplay and correctness.

---

v0.0 — Project setup (tiny)
- Goals
  - Create `dev` branch and a minimal README/plan files (spec + roadmap).
  - Small dev conveniences: debug flag, fixed-seed launch (optional).
- Non-goals
  - CI, project board, formal tests.
- Acceptance criteria
  - `dev` branch exists and README/ROADMAP.md/spec.md in repo.

---

v0.1 — Core playable loop (MVP)
- Goals (the essential MVP)
  - Rendering pipeline / RenderManager with simple layer canvases (back, default, front).
  - Procedural world generation: 3 layers (-1, 0, 1), seeded, lazy column generation.
  - Player: movement, camera follow, layer switching (Q/E).
  - Block model: canonical prototypes (block proto), block placement and removal on current layer.
  - Mining: Omnitool mines blocks; tier gating for higher-tier ores (basic check).
  - Inventory & hotbar (9 slots) with stacks (64); simple UI to inspect and select hotbar slot.
  - Drops: destroying a block spawns Drop entities; drops fall, despawn, and are picked up into player inventory.
  - Entity lifecycle & physics basics: update/draw pattern, simple gravity for drops.
- Non-goals
  - Crafting, Ages, machines, enemies, snapshot/death.
- Acceptance criteria
  - Player can move around and switch layers.
  - World is generated and visible across three layers with visual dim/alpha rules and parallax.
  - Player can mine blocks (respecting Omnitool tier rules) and get drops in the world.
  - Player can place blocks from inventory/hotbar on the active layer.
  - Picked-up drops merge into inventory respecting stack sizes.
  - The basic UI shows hotbar, selected item, and item counts.

---

v0.2 — Crafting and Ages (basic progression)
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

v0.3 — Optional: Enemies (deferred for MVP)
- Goals
  - Basic enemy types (passive/hostile), layer-aware spawn rules, simple pathing/aggro.
  - Health/damage system for player and enemies.
- Non-goals
  - Complex AI, groups, advanced behaviors.
- Acceptance criteria
  - Hostile enemies can spawn and damage the player; enemies obey layer restrictions for interaction.

---

v0.4 — Death & snapshot restore
- Goals
  - Automatic periodic snapshot system saving world and player state (lightweight).
  - On death, restore the last snapshot (no manual saves).
- Non-goals
  - Long-term persistence and multi-snapshot UI management.
- Acceptance criteria
  - If player dies, the world and player inventory/position/health restore to the last snapshot slot.

---

v0.5 — UX, polish, and quality-of-life
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

---

Estimates (very rough)
- v0.0: 0.5–1 day
- v0.1: 2–6 weeks (depending on how fast you iterate and test)
- v0.2: 1–2 weeks
- v0.3: 1 week (optional)
- v0.4: 2–4 days
- v0.5 → v1.0: several weeks for polishing and extra features

---

How I can help
- I can scaffold PRs for the high-priority v0.1 tasks (protos normalization, RenderManager, world-gen skeleton, Drop entity) and generate small, reviewable patches.
- If you want, I will start by preparing the first PRs for:
  1. canonical `world:get_block_proto` / `world:set_block` normalization,
  2. `Inventory:add` normalization and canonical entry shape,
  3. default `Item:drop` fallback and simple `Drop` entity scaffold.

If you'd like me to commit the ROADMAP.md to `dev`, say “commit ROADMAP to dev” and I'll create the patch/PR for you. Otherwise, copy this into the repo when you're ready.
