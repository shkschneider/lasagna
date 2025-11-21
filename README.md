# 2D Layered Exploration Game — Design Notes

## Table of Contents
1. [Core Concept](#core-concept)
2. [Player Mechanics](#player-mechanics)
3. [World & Layers](#world--layers)
4. [Resources & Tiers](#resources--tiers)
5. [Tool System](#tool-system)
6. [Inventory & Stacks](#inventory--stacks)
7. [Crafting & Workstations](#crafting--workstations)
8. [Machines & Automation](#machines--automation)
9. [Power System (Flux)](#power-system-flux)
10. [Movement & Layers](#movement--layers)
11. [Enemies & AI](#enemies--ai)
12. [Survival Mechanics](#survival-mechanics)
13. [Death Mechanic](#death-mechanic)
14. [End-Goal](#end-goal)
15. [Miscellaneous Design Notes](#miscellaneous-design-notes)

---

## Core Concept

- 2D layered world, procedurally generated, inspired by Starbound, Minecraft, and modded Minecraft.  
- **Layers:** Three layers, -1 (back), 0 (default), 1 (front). Player can interact only with current layer.  
- Exploration, resource gathering, building, and tech progression are the core gameplay loops.  
- Open-world, no forced questing, base-building optional.  
- Lore: The player is a **Seed** sent by the **Hive** to colonize worlds. Many Seeds fail, most die. Success is measured by Age progression.

---

## Player Mechanics

- **Movement:** WASD for movement. Q/E to move between layers.  
- **Inventory:** Hotbar of 9 slots; inventory rows of 9 slots, each Age unlocks an additional row.  
- **Omnitool:** Unbreakable, tiered by Age. Handles all gathering, building, and machine interaction.  
- **Health:** Only health, no hunger or thirst. Passive regen is not present; healing is via items.  
- **Stack Size:** Fixed at 64 for all items.  
- **No bags or quick-slot systems** beyond the Omnitool interface.  

---

## World & Layers

- **Layers:**  
  - -1: back layer, rougher terrain, more caves, deep ores  
  - 0: default layer, surface, basic ores, initial base building  
  - 1: front layer, smoother, some surface resources, optional structures  
- **Drawing:**  
  - Layer in front: semi-transparent  
  - Layer behind: dimmed/darkened  
  - Parallax may be applied for visual depth  
- **Navigation Restrictions:** Player can only interact with the current layer; must travel through natural gaps to access another layer.  
- **Caves & Secrets:** Layer -1 and 0 contain caves, ores, gems (Cobalt, etc.), hidden rooms.  
- **Vertical Biomes:** Biomes can extend vertically. Layer-specific specialty materials.  

---

## Resources & Tiers

### Resource Types

- **Wood & Stone** → early Age  
- **Copper & Tin → Bronze** → mid-Age  
- **Iron, Lead, Zinc → Brass** → Iron Age  
- **Steel (from Iron + Coal)** → Steel Age  
- **Gold** → for economy  
- **Cobalt** → late-game tech gem

### Resource Distribution

- Ores spawn in **veins**, not isolated.  
- Basic resources on surface; iron deeper; Cobalt and advanced ores layer -1 and deeper.  
- Infinite or renewable resources may exist via anomalies (future).  

---

## Tool System

- Omnitool tiers:  
  - Wood → Stone → Copper → Bronze → Iron → Steel → Cobalt  
- Omnitool **never breaks**.  
- Higher tier tools are required to mine higher-tier resources.  
- No separate tool types for pickaxe, axe, etc.  

---

## Inventory & Stacks

- **Stack size fixed at 64** for all items.  
- Inventory grows by **one 9-slot row per Age**.  
- Hotbar: 9 slots.  
- Inventory expansion and stack size progression tied to Age.  

---

## Crafting & Workstations

| Age | Crafting Station | Notes |
|-----|----------------|-------|
| 0   | Hand crafting  | Primitive tools, wood/stone conversions |
| 1   | Workbench      | Early tools, basic components |
| 2   | Furnace + Workbench | Smelting copper/tin/bronze/iron |
| 3   | Kiln + Anvil   | Advanced metal shaping, ceramics, flux prep |
| 4+  | Machines       | Automated smelters, assemblers, fabricators, etc. |

- Early machines require **manual cranking** (player-powered).  
- Later machines become **Flux-powered**, wireless, scalable.  
- Crafting progression linear and tied to Ages.  

---

## Machines & Automation

- **Processing:** Batch processing of similar items (efficiency scales with quantity).  
- **Automation complexity:** Mindustry-lite. Optional for convenience, not mandatory.  
- **Machines:**  
  - Single-block: furnace, workbench, anvil, grinder, recycler  
  - Multi-block: foundry, power plant, assembler, teleporter pads (late game)  
- No automatic movement of items unless player-built tubes/chutes (optional, late-game).  

---

## Power System (Flux)

- Early Ages: **manual cranks** power machines.  
- Steel Age+: **Flux system** (electricity), wireless within a radius.  
- Power generators: coal, solar, combustion, batteries.  
- Flux-powered machines scale in speed based on power input.  

---

## Movement & Layers

- Layers -1, 0, 1  
- Player interacts with **current layer only**  
- Layer in front semi-transparent, layer behind dimmed  
- Enemies: can interact across layers; attacks from any layer can hit the player  
- Restrictions on traveling between layers enforced naturally via terrain gaps  

---

## Enemies & AI

- Optional / light early on; more relevant mid-late game  
- Types: Passive, Neutral, Hostile  
- Passive: flee, never attack  
- Neutral: retaliate if attacked  
- Hostile: actively seek player  
- AI respects layer system; cross-layer interactions possible  

*(Detailed feral suit/seed-failure mechanics saved for later)*  

---

## Survival Mechanics

- Health-only system  
- No hunger or thirst  
- Healing via items only  
- Surface is “safe zone”; underground may contain more dangerous wildlife  
- Weather mechanics planned for future, not yet implemented  

---

## Death Mechanic

- **Death triggers full automatic restore** to a previous snapshot of the world and player.  
- Player **cannot manually save**; snapshots are automatic and hidden.  
- Snapshots store: world state (blocks, machines, enemies) + player state (inventory, position, health, Flux).  
- Light death, no penalty beyond temporary failure.  
- Encourages risk-taking and exploration.  

---

## End-Goal

- Current goal: progress through Ages and survive/colonize a single planet.  
- FTL / Hive contact is locked until late Ages (can be implemented later).  
- Endgame could eventually include:  
  - starting new worlds  
  - multiplayer expansion  
  - rogue objectives (freeing other Seeds)  
- For the prototype: focus on self-contained progression and Age milestones.  

---

## Miscellaneous Design Notes

- Layers: -1, 0, 1; infinite upward for huge buildings, lower limit for deep mining/hell biome.  
- No teleportation mechanic yet; possible future fast travel solution.  
- Bases: no NPCs, player blocks cannot be destroyed by mobs.  
- No pack mode for Omnitool; machines are not teleportable.  
- Loot and ruins purely for exploration/lore, not quests.  
- Tech tree completely linear, but Ages can be rushed if player chooses.  
- Ages last hours of playtime but scale with exploration and pace of the player.  
- Machines and inventory expansions tied directly to Age milestones.  

---

**End of Design Document**

