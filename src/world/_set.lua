local Registry = require "src.game.registries"
local BLOCKS = Registry.blocks()

-- Set block value at position (0 = air, 1 = solid)
function World.set_block(self, z, col, row, block_id)
    local data = self.generator.data
    if row < 0 or row >= data.height then
        return false
    end

    -- Request column generation with high priority (user action)
    self.generator:generate_column(z, col, true)

    -- Ensure the column structure exists
    if not data.columns[z] then
        data.columns[z] = {}
    end
    if not data.columns[z][col] then
        data.columns[z][col] = {}
    end

    -- Convert block ID to noise value (0 = air, 1 = solid)
    local value = (block_id == BLOCKS.AIR) and 0 or 1

    -- Track change from generated terrain
    if not data.changes[z] then
        data.changes[z] = {}
    end
    if not data.changes[z][col] then
        data.changes[z][col] = {}
    end
    data.changes[z][col][row] = value

    data.columns[z][col][row] = value
    return true
end

