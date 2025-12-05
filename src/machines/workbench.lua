local Object = require "core.object"
local Machine = require "src.machines"
local Vector = require "src.game.vector"
local ItemDrop = require "src.entities.itemdrop"

local Workbench = Object {
    id = "workbench",
    type = "machine",
    RECIPES = require "data.recipes.workbench",
}

-- Create a new Workbench entity
function Workbench.new(x, y, layer, block_id)
    local workbench = Machine.new(x, y, layer, block_id)
    workbench.type = "machine"  -- Keep consistent type for entity system
    return setmetatable(workbench, { __index = Workbench })
end

-- Get all itemdrops on top of this workbench
function Workbench.get_items_on_top(self)
    local items = {}

    -- Calculate the position on top of the workbench
    local top_y = self.position.y - BLOCK_SIZE

    -- Get all drops from the entity system
    local drops = G.entities:getByType("drop")

    for _, drop in ipairs(drops) do
        -- Check if drop is on the same layer
        if drop.position.z == self.position.z and not drop.dead then
            -- Check if drop is horizontally aligned with the workbench
            local dx = math.abs(drop.position.x - self.position.x)

            -- Check if drop is on top (within BLOCK_SIZE height tolerance)
            local dy = drop.position.y - top_y

            -- Drop is "on top" if it's within a block's width horizontally
            -- and within a block's height vertically above the workbench
            if dx < BLOCK_SIZE and dy >= 0 and dy < BLOCK_SIZE then
                table.insert(items, drop)
            end
        end
    end

    return items
end

-- Count items by block_id from a list of itemdrops
function Workbench.count_items(items)
    local counts = {}
    for _, drop in ipairs(items) do
        local block_id = drop.block_id
        counts[block_id] = (counts[block_id] or 0) + drop.count
    end
    return counts
end

-- Check if current items match a recipe
function Workbench.match_recipe(item_counts)
    for _, recipe in ipairs(Workbench.RECIPES) do
        local matches = true

        -- Check if all required inputs are present with exact counts
        for block_id, required_count in pairs(recipe.inputs) do
            if (item_counts[block_id] or 0) ~= required_count then
                matches = false
                break
            end
        end

        -- Also ensure no extra items are present
        if matches then
            for block_id, count in pairs(item_counts) do
                if not recipe.inputs[block_id] then
                    matches = false
                    break
                end
            end
        end

        if matches then
            return recipe
        end
    end

    return nil
end

-- Update method - checks for items on top and processes recipes
function Workbench.update(self, dt)
    -- Get items on top of the workbench
    local items = self:get_items_on_top()

    if #items == 0 then
        return
    end

    -- Count items by block_id
    local item_counts = Workbench.count_items(items)

    -- Try to match a recipe
    local recipe = Workbench.match_recipe(item_counts)

    if recipe then
        -- Recipe matched! Consume input items and spawn output

        -- Mark all input items as dead (consumed)
        for _, drop in ipairs(items) do
            drop.dead = true
        end

        -- Spawn output items at the bottom of the workbench
        -- Output format: { [block_id] = count, ... }
        for block_id, count in pairs(recipe.output) do
            local output_x = self.position.x + BLOCK_SIZE / 2
            local output_y = self.position.y + BLOCK_SIZE + BLOCK_SIZE / 2
            local output_drop = ItemDrop.new(
                output_x,
                output_y,
                self.position.z,
                block_id,
                count,
                300,  -- lifetime
                0.5   -- pickup delay
            )
            G.entities:add(output_drop)
        end
    end
end

-- Inherit draw method from Machine
Workbench.draw = Machine.draw

return Workbench
