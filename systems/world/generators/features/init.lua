-- World Features Module
-- Features are world generation additions that place structures, decorations,
-- and other elements beyond basic terrain and ores.
--
-- To add a new feature:
--   1. Create a new file in this directory (e.g., trees.lua)
--   2. Implement a function(column_data, world_col, z, base_height, world_height)
--   3. Require and call it in systems/world/generator.lua's run_generator()
--
-- Feature examples that could be added:
--   - trees.lua: Surface trees with wood and leaves
--   - caves.lua: Underground cave systems
--   - structures.lua: Ruins, buildings, or other structures
--   - vegetation.lua: Flowers, mushrooms, tall grass
--   - water.lua: Lakes, rivers, water features

return {}
