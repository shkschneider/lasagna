-- Inventory
-- A reusable storage container (array of Stacks)
-- Used for hotbar, backpack, chests, etc.
-- Simple API: has(), can_give(), can_take(), take(), give()

local Love = require "core.love"
local Object = require "core.object"
local Stack = require "src.data.stack"

local Inventory = Object {
    id = "inventory",
}

-- Create a new storage with a given number of slots
function Inventory.new(size)
    local inventory = {
        id = "inventory",
        slots = {},
        size = size or 9,
        selected_slot = 1,  -- Currently selected slot (for hotbar-like selection)
    }
    -- Initialize empty slots
    for i = 1, inventory.size do
        inventory.slots[i] = Stack.empty()
    end
    return setmetatable(inventory, { __index = Inventory })
end

-- Get the stack in the currently selected slot
function Inventory.get_selected(self)
    return self.slots[self.selected_slot]
end

-- Remove items from the currently selected slot
-- Returns the number actually removed
function Inventory.remove_from_selected(self, count)
    count = count or 1
    local slot = self.slots[self.selected_slot]

    if not slot then
        return 0
    end

    local removed = slot:remove(count)

    -- Clear slot if empty
    if slot:is_empty() then
        self.slots[self.selected_slot] = nil
    end

    return removed
end

-- Check if storage has at least the given stack (same type/id and count)
-- @param stack: Stack to check for
-- @return true if storage contains at least this many items
function Inventory.has(self, stack)
    if stack == nil or stack:is_empty() then
        return true
    end

    local needed = stack.count
    local found = 0

    for i = 1, self.size do
        local slot = self.slots[i]
        if slot and slot:can_merge(stack) then
            found = found + slot.count
            if found >= needed then
                return true
            end
        end
    end

    return false
end

-- Check if can give (remove) the given stack from storage
-- @param stack: Stack to remove
-- @return true if can remove all items
function Inventory.can_give(self, stack)
    return self:has(stack)
end

-- Check if can take (add) the given stack to storage
-- @param stack: Stack to add
-- @return true if can add all items
function Inventory.can_take(self, stack)
    if stack == nil or stack:is_empty() then
        return true
    end

    local remaining = stack.count

    -- First try to stack with existing slots
    for i = 1, self.size do
        local slot = self.slots[i]
        if slot and slot:can_merge(stack) then
            remaining = remaining - slot:space()
            if remaining <= 0 then
                return true
            end
        end
    end

    -- Then try empty slots
    for i = 1, self.size do
        if self.slots[i] == nil then
            remaining = remaining - Stack.MAX_SIZE
            if remaining <= 0 then
                return true
            end
        end
    end

    return remaining <= 0
end

-- Input (add) a stack to storage
-- @param stack: Stack to add
-- @return true if all items were added, false if some couldn't fit
function Inventory.take(self, stack)
    if stack == nil or stack:is_empty() then
        return true
    end

    local remaining = stack.count

    -- First try to stack with existing slots
    for i = 1, self.size do
        local slot = self.slots[i]
        if slot and slot:can_merge(stack) then
            local added = slot:add(remaining)
            remaining = remaining - added
            if remaining <= 0 then
                return true
            end
        end
    end

    -- Then try empty slots
    for i = 1, self.size do
        if self.slots[i] == nil then
            local to_add = math.min(remaining, Stack.MAX_SIZE)
            self.slots[i] = Stack.new(stack:get_id(), to_add, stack:get_type())
            remaining = remaining - to_add
            if remaining <= 0 then
                return true
            end
        end
    end

    return remaining <= 0
end

-- Output (remove) a stack from storage
-- @param stack: Stack describing what to remove
-- @return true if all items were removed, false if not enough items
function Inventory.give(self, stack)
    if stack == nil or stack:is_empty() then
        return true
    end

    -- First check if we have enough
    if not self:has(stack) then
        return false
    end

    local remaining = stack.count

    -- Remove from slots
    for i = 1, self.size do
        local slot = self.slots[i]
        if slot and slot:can_merge(stack) then
            local removed = slot:remove(remaining)
            remaining = remaining - removed

            -- Clear empty slots
            if slot:is_empty() then
                self.slots[i] = nil
            end

            if remaining <= 0 then
                return true
            end
        end
    end

    return remaining <= 0
end

-- Get the stack at a specific slot index
function Inventory.get_slot(self, index)
    if index < 1 or index > self.size then
        return nil
    end
    return self.slots[index]
end

-- Set a stack at a specific slot index
function Inventory.set_slot(self, index, stack)
    if index < 1 or index > self.size then
        return false
    end
    self.slots[index] = stack
    return true
end

-- Clear a slot
function Inventory.clear_slot(self, index)
    return self:set_slot(index, nil)
end

-- Get total count of a specific item/block across all slots
function Inventory.count(self, id, id_type)
    local total = 0
    for i = 1, self.size do
        local slot = self.slots[i]
        if slot then
            if id_type == "item" and slot.item_id == id then
                total = total + slot.count
            elseif id_type == "block" and slot.block_id == id then
                total = total + slot.count
            elseif id_type == nil and slot:get_id() == id then
                total = total + slot.count
            end
        end
    end
    return total
end

-- Check if storage is empty
function Inventory.is_empty(self)
    for i = 1, self.size do
        if self.slots[i] ~= nil then
            return false
        end
    end
    return true
end

-- Check if storage is full (no empty slots and all stacks full)
function Inventory.is_full(self)
    for i = 1, self.size do
        local slot = self.slots[i]
        if slot == nil or not slot:is_full() then
            return false
        end
    end
    return true
end

-- Get number of empty slots
function Inventory.empty_slots(self)
    local count = 0
    for i = 1, self.size do
        if self.slots[i] == nil then
            count = count + 1
        end
    end
    return count
end

return Inventory
