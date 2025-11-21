```markdown
# FIXME — Known problems and suggested fixes

This file captures the implementation and architecture issues I found while reviewing the repo and the dev README. Each entry lists: problem, severity, evidence (file locations / snippets), and recommended fix + acceptance criteria.

---

## 1) Mixed block representation in world storage
- Severity: HIGH
- Problem:
  - The world stores blocks inconsistently as either prototype tables or string IDs (e.g. "air", "out", "__empty").
  - Many callers must test `type(block_type) == "table"` vs string values.
- Evidence:
  - entities/bullet.lua — checks `type(block_type) == "table"` and other branches test `block_type ~= "air" and block_type ~= "out"`.
  - entities/rocket.lua — similar checks and sometimes uses `world:set_block(..., "__empty")`.
  - world/block.lua and data/blocks.lua define Block prototypes as tables.
- Recommended fix:
  - Standardize world storage to one canonical representation (preferably a prototype table or a small proto wrapper { id, proto }).
  - Add accessors: `world:get_block_proto(z, col, row)` returning proto or nil; `world:set_block(z, col, row, proto_or_id)` which normalizes input.
- Acceptance criteria:
  - No `type(... ) == "table"` checks around block lookup remain in the codebase. Callers use the accessor and receive either a prototype table or nil.

---

## 2) Item/block drop behavior is optional and can silently lose items
- Severity: HIGH
- Problem:
  - Many code paths call `proto:drop(...)` only when `proto.drop` exists. If an item prototype lacks `drop`, items may be discarded with no spawn of a Drop entity.
- Evidence:
  - entities/player.lua — `release_held_item` and `drop_single_item_to_world` call `proto:drop` guarded by `type(proto.drop) == "function"`, then set `ui.held_item = nil`.
  - data/items.lua — Items.gun and Items.rocket_launcher have no `drop` implementation.
  - data/blocks.lua / world/block.lua — Block:drop exists but bedrock overrides it to return false.
- Recommended fix:
  - Add a default `Item:drop` implementation that spawns a Drop entity with given proto/count.
  - Treat `drop=false` explicitly for non-droppable items.
  - Update Player drop code to always route through a canonical drop API (never silently discard).
- Acceptance criteria:
  - Dropping any held item results either in a Drop entity in the world or an explicit non-droppable error; no silent loss occurs.

---

## 3) Inventory entry shape is inconsistent
- Severity: HIGH
- Problem:
  - Inventory consumers expect either a raw proto table, or an object `{ proto, count }`. Code repeatedly uses `item.proto or item`.
  - This dual-shape pattern increases cognitive load and bugs.
- Evidence:
  - entities/player.lua — `has_gun_selected()` uses `local proto = item.proto or item`.
  - entities/player.lua — inventory initialization uses `self.inventory.belt:add(Blocks.cobblestone, 64)` and similar calls.
- Recommended fix:
  - Pick a canonical inventory entry format (recommended: `{ proto = <proto>, count = n }`).
  - Normalize all inputs at `Inventory:add(...)` and expose accessors like `Inventory:get_selected_proto()` and `Inventory:get_selected_count()` so callers don't need to normalize.
- Acceptance criteria:
  - Codebase uses a single inventory entry shape; helper accessors are used everywhere.

---

## 4) Global state coupling (G.*) and mixed responsibilities
- Severity: MEDIUM
- Problem:
  - Heavy reliance on `G.*` globals tightly couples modules (world, camera, player, renderer), making testing, refactor, and engine migration harder.
- Evidence:
  - Many files reference `G.world`, `G.camera`, `G.*`.
- Recommended fix:
  - Introduce a `Game` object that wires subsystems and passes references explicitly to modules that need them.
  - Reduce global reads/writes; prefer dependency injection.
- Acceptance criteria:
  - Decreased global accesses and clearer module boundaries; easier to unit test modules in isolation.

---

## 5) Rendering and canvas management is not centralized
- Severity: MEDIUM
- Problem:
  - Canvas creation/usage is not clearly centralized; canvases may be created in multiple places or not managed consistently.
  - This complicates compositing, layer rendering, and potential optimizations (partial redraws, effects).
- Evidence:
  - No single renderer module owning canvases was found during the review; main.lua / game.lua likely contain drawing code; earlier search for newCanvas/setCanvas returned uncertain results.
- Recommended fix:
  - Introduce a `RenderManager` that creates and owns canvases for world layers and UI, provides a simple API for clients to render to layer canvases, then composites to screen with front/back dimming rules.
- Acceptance criteria:
  - All canvases are created in one module; drawing code uses the RenderManager API.

---

## 6) Lack of tests and instrumentation
- Severity: MEDIUM
- Problem:
  - There are no headless unit tests or assertion harnesses for core invariants (inventory, drops, block set/get, entity lifecycle).
  - No instrumentation makes it hard to find performance hotspots.
- Evidence:
  - No `/tests` folder and no CI/test config present.
- Recommended fix:
  - Add a lightweight test harness (scripts under `/tests` or `/scripts/debug`) that can run core invariants headless.
  - Add timing instrumentation in the main loop (DEBUG flag) to measure time in world update, entity updates, rendering, etc.
- Acceptance criteria:
  - Core invariant tests exist and can be run locally or in CI; profiling data available when requested.

---

## 7) Entity code manipulates world directly without clear abstractions
- Severity: MEDIUM
- Problem:
  - Entities (bullets, rockets, player interactions) call `world:set_block` and `block_proto:drop` directly with mixed assumptions about representations.
  - This duplicates logic and couples entities to world internals.
- Evidence:
  - entities/bullet.lua and entities/rocket.lua directly call `world:set_block` and `block_proto:drop`.
- Recommended fix:
  - Expose world helper functions for "destroy block at (z,col,row) and spawn drops" so callers don't repeat normalization checks.
- Acceptance criteria:
  - Entity code calls high-level world APIs and no longer repeats block normalization or drop logic.

---

## 8) Drop entity and Item/Block proto interface inconsistency
- Severity: MEDIUM
- Problem:
  - Prototype objects (Item vs Block) do not consistently implement the same minimal interface (e.g., name, max_stack, drop), causing code that handles Drops to branch often.
- Evidence:
  - data/items.lua sets `max_stack = 1` but lacks `drop()`; blocks have `drop()` in Block class.
  - Drop entity uses `proto.max_stack` and `proto.drop`.
- Recommended fix:
  - Define and enforce a minimal proto interface (name, max_stack, optional drop function, icon) and normalize prototypes at load time.
- Acceptance criteria:
  - All protos validate/normalize to include required fields during data load.

---

## 9) Canvas/draw call uncertainty (possible draw outside canvas)
- Severity: LOW → MEDIUM (depends on usage)
- Problem:
  - Earlier search didn't find canonical canvas creation; it's unclear whether all world drawing is rendered to canvases or some draw directly to screen. This can lead to inconsistent compositing.
- Evidence:
  - Rendering code spread across entities and game.lua; need to centralize.
- Recommended fix:
  - As part of RenderManager work, ensure world layers render to their dedicated canvases and UI draws to screen afterwards.
- Acceptance criteria:
  - All world layer rendering occurs via RenderManager canvases; no entity performs love.graphics.newCanvas / setCanvas outside the manager.

---

## 10) Migration assumptions: porting risks & EAL missing
- Severity: INFO (non-blocking)
- Problem:
  - If you decide to migrate to Go/raylib, there is no Engine Abstraction Layer (EAL) design in the repo yet.
- Evidence:
  - No EAL doc or compatibility layer between gameplay code and Love2D APIs.
- Recommended fix:
  - Create a small EAL spec mapping used Love2D APIs to engine-agnostic primitives (draw_rect, create_canvas, get_mouse_pos, load_image, play_sound).
- Acceptance criteria:
  - EAL doc exists and covers all used Love2D functionality.

---

# Notes & next actions
- Immediate high-priority tasks: (1) standardize block proto representation, (2) implement guaranteed drop behavior / fallback, (3) normalize inventory shape.
- Medium-term: centralize renderer, decouple globals, add tests and profiling.
- I can prepare focused PRs for T1–T3 if you want; say which task to start and whether to push PRs directly to `dev`.

```
