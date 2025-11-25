-- Inventory System
-- Manages player inventories (hotbar and backpack)
-- Handles UI interaction and inventory logic

local Object = require "core.object"
local StackComponent = require "components.stack"
local InventoryComponent = require "components.inventory"

local InventorySystem = Object.new {
    id = "inventory",
    priority = 100,  -- Before interface (110)
    -- Hotbar constants
    HOTBAR_SIZE = 9,
    -- Backpack constants (3 rows of 9)
    BACKPACK_ROWS = 3,
    BACKPACK_COLS = 9,
    -- Currently selected hotbar slot
    selected_slot = 1,
}

function InventorySystem.load(self)
    self.selected_slot = 1
end

-- Get the currently selected slot index
function InventorySystem.get_selected_slot(self)
    return self.selected_slot
end

-- Set the selected slot index
function InventorySystem.set_selected_slot(self, slot)
    if slot >= 1 and slot <= self.HOTBAR_SIZE then
        self.selected_slot = slot
    end
end

-- Get the stack in the currently selected hotbar slot
function InventorySystem.get_selected_stack(self)
    if not G.player or not G.player.hotbar then
        return nil
    end
    return G.player.hotbar:get_slot(self.selected_slot)
end

-- Get the block_id of the selected item (for building)
function InventorySystem.get_selected_block_id(self)
    local stack = self:get_selected_stack()
    if stack then
        return stack.block_id
    end
    return nil
end

-- Get the item_id of the selected item (for weapons, tools)
function InventorySystem.get_selected_item_id(self)
    local stack = self:get_selected_stack()
    if stack then
        return stack.item_id
    end
    return nil
end

-- Add a block to player's inventory (tries hotbar first, then backpack)
-- Returns true if all items were added
function InventorySystem.add_block(self, block_id, count)
    count = count or 1
    if not G.player then
        return false
    end

    local stack = StackComponent.new(block_id, count, "block")

    -- Try hotbar first
    if G.player.hotbar:can_input(stack) then
        return G.player.hotbar:input(stack)
    end

    -- Try backpack
    if G.player.backpack and G.player.backpack:can_input(stack) then
        return G.player.backpack:input(stack)
    end

    -- Try partial: fill hotbar then backpack
    local remaining = count

    -- Fill hotbar
    for i = 1, G.player.hotbar.size do
        local slot = G.player.hotbar.slots[i]
        if slot and slot.block_id == block_id then
            local added = slot:add(remaining)
            remaining = remaining - added
            if remaining <= 0 then
                return true
            end
        end
    end

    -- Fill empty hotbar slots
    for i = 1, G.player.hotbar.size do
        if G.player.hotbar.slots[i] == nil then
            local to_add = math.min(remaining, StackComponent.MAX_SIZE)
            G.player.hotbar.slots[i] = StackComponent.new(block_id, to_add, "block")
            remaining = remaining - to_add
            if remaining <= 0 then
                return true
            end
        end
    end

    -- Fill backpack
    if G.player.backpack then
        for i = 1, G.player.backpack.size do
            local slot = G.player.backpack.slots[i]
            if slot and slot.block_id == block_id then
                local added = slot:add(remaining)
                remaining = remaining - added
                if remaining <= 0 then
                    return true
                end
            end
        end

        for i = 1, G.player.backpack.size do
            if G.player.backpack.slots[i] == nil then
                local to_add = math.min(remaining, StackComponent.MAX_SIZE)
                G.player.backpack.slots[i] = StackComponent.new(block_id, to_add, "block")
                remaining = remaining - to_add
                if remaining <= 0 then
                    return true
                end
            end
        end
    end

    return remaining <= 0
end

-- Add an item to player's inventory (tries hotbar first, then backpack)
-- Returns true if all items were added
function InventorySystem.add_item(self, item_id, count)
    count = count or 1
    if not G.player then
        return false
    end

    local stack = StackComponent.new(item_id, count, "item")

    -- Try hotbar first
    if G.player.hotbar:can_input(stack) then
        return G.player.hotbar:input(stack)
    end

    -- Try backpack
    if G.player.backpack and G.player.backpack:can_input(stack) then
        return G.player.backpack:input(stack)
    end

    return false
end

-- Remove items from the selected slot
-- Returns the number actually removed
function InventorySystem.remove_from_selected(self, count)
    count = count or 1
    local stack = self:get_selected_stack()
    if not stack then
        return 0
    end

    local removed = stack:remove(count)

    -- Clear slot if empty
    if stack:is_empty() then
        G.player.hotbar:clear_slot(self.selected_slot)
    end

    return removed
end

-- Check if player has a specific block
function InventorySystem.has_block(self, block_id, count)
    count = count or 1
    if not G.player then
        return false
    end

    local stack = StackComponent.new(block_id, count, "block")

    -- Check hotbar
    if G.player.hotbar:has(stack) then
        return true
    end

    -- Check backpack
    if G.player.backpack and G.player.backpack:has(stack) then
        return true
    end

    -- Check combined count
    local total = G.player.hotbar:count(block_id, "block")
    if G.player.backpack then
        total = total + G.player.backpack:count(block_id, "block")
    end

    return total >= count
end

-- Check if player has a specific item
function InventorySystem.has_item(self, item_id, count)
    count = count or 1
    if not G.player then
        return false
    end

    local stack = StackComponent.new(item_id, count, "item")

    -- Check hotbar
    if G.player.hotbar:has(stack) then
        return true
    end

    -- Check backpack
    if G.player.backpack and G.player.backpack:has(stack) then
        return true
    end

    return false
end

return InventorySystem
