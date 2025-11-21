# TODO

## Engine decision (short)
- Continue with Love2D for prototype and early development.
- Consider Go + raylib only if:
  - You need native multithreading across many cores for simulation.
  - You require a static native binary or tighter memory/control for server-side workloads.
  - You require high-performance native networking (authoritative multiplayer) that Lua can’t satisfy easily.

## Immediate high-priority fixes (blockers)
These should be done before large feature work or migration.

T1 — Standardize block/item prototypes and world storage (HIGH)
- Action:
  - Introduce `world:get_block_proto(z, col, row)` returning either nil or the prototype table.
  - Ensure `world:set_block(z, col, row, proto_or_id)` normalizes and stores a canonical representation.
  - Replace scattered `type(block_type) == "table"` checks with the accessor.
- Acceptance criteria:
  - No code performs `type(...) == "table"` checks for block types.
  - All callers operate against prototype tables or nil.

T2 — Guarantee drop behavior / prevent silent item loss (HIGH)
- Action:
  - Add a default `Item:drop(world, px, py, z, count)` implementation that spawns a `Drop` entity using the proto and count.
  - Ensure `Player:release_held_item` and other drop code always call a drop path (fallback to default when missing).
- Acceptance criteria:
  - Dropping any held item always creates a `Drop` entity or explicitly returns an error if non-droppable.

T3 — Normalize inventory entry shape (MED)
- Action:
  - Choose canonical shape: `{ proto = <proto>, count = n }`.
  - Update `Inventory:add(...)` to accept proto or `{proto,count}` and store canonical entries.
  - Add helpers: `Inventory:get_selected_proto()`, `Inventory:get_selected_count()`.
- Acceptance criteria:
  - All inventory consumers use the helper accessors and no longer do `item.proto or item`.

## Near-term improvements (medium effort)
T4 — Centralize rendering and canvas management (MED)
- Action:
  - Create `RenderManager` (or `renderer.lua`) that owns canvas creation and lifecycle.
  - Render each layer (back, default, front) to its own canvas, then composite to the screen with alpha/brightness rules.
  - Ensure UI/HUD draw calls happen after canvas compositing.
- Acceptance criteria:
  - One module creates and manages canvases.
  - Visual parity retained; easier to add post-processing later.

T5 — Decouple subsystems and reduce globals (MED)
- Action:
  - Refactor code so World, Entities, Inventory, Renderer have explicit APIs and minimal global reliance.
  - Introduce a small Game object that wires modules together.
- Acceptance criteria:
  - Fewer G.* accesses; core systems accept dependencies via constructor or init.

T6 — Add headless tests and debug harness (MED)
- Action:
  - Add small test scripts (under `/tests` or `scripts/debug`) to verify:
    - Add/remove item invariants
    - Block place/remove & drop spawn
    - Basic entity lifecycle (spawn, run update, removed)
  - Add a debug flag to run tests in CI or locally.
- Acceptance criteria:
  - A test run that prints PASS/FAIL for core invariants.

T7 — Instrumentation & profiling (LOW)
- Action:
  - Add timing in main update loop: record time spent in world update, entity updates, rendering, and input.
  - Generate simple logs or CSV for a run.
- Acceptance criteria:
  - Profiling data identifies hotspots for future optimization.

## Migration plan to Go + raylib (only if required)
Principles:
- Port gradually. Keep gameplay code engine-agnostic where possible.
- Implement an Engine Abstraction Layer (EAL) mapping Love2D calls to simple functions.

M1 — EAL spec (LOW)
- Create a document mapping used Love APIs (graphics, input, audio, filesystem) to EAL functions.

M2 — Go skeleton + EAL implementation (LOW→MED)
- Create a Go project skeleton with raylib bindings.
- Implement EAL functions that the game needs.

M3 — Port deterministic subsystems first (MED)
- Port world generation, verify parity using checksums or deterministic seeds.

M4 — Port physics & entity simulation (MED→HIGH)
- Ensure update semantics match Lua implementation; create tests that compare behaviors.

M5 — Port rendering & UI (MED→HIGH)
- Implement canvas/compositing with raylib render textures.

## Agent-assisted tasks (what I can automate)
- Repo-wide search and safe automated code transforms (normalize prototypes).
- Create small PRs that implement T1–T3 with tests.
- Add RenderManager scaffold and open PR for review.
- Scaffold Go/raylib skeleton and EAL doc for incremental migration.
- Create CI tasks to run headless tests and linters.

## Branching & PR strategy
- Work on `dev` as main integration branch.
- Create small feature branches:
  - `dev/standardize-protos`
  - `dev/drop-fallback`
  - `dev/inventory-normalize`
  - `dev/render-manager`
  - `dev/go-skeleton`
- Keep PRs small and focused. Add tests where possible.

## Estimates
- T1–T3 (high priority): 1–3 days total (across small PRs).
- T4–T6: 1–2 weeks.
- Migration skeleton (if chosen): 2–4 weeks for a minimal playable port.
