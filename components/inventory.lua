-- Inventory component
-- A collection of slots, each holding a StackComponent
-- Simple API: has(), can_output(), can_input(), input(), output()

local StackComponent = require "components.stack"

local InventoryComponent = {}

-- Create a new inventory with a given number of slots
function InventoryComponent.new(size)
    local instance = {
        id = "inventory",
        slots = {},
        size = size or 9,
    }

    -- Initialize empty slots
    for i = 1, instance.size do
        instance.slots[i] = nil
    end

    return setmetatable(instance, { __index = InventoryComponent })
end

-- Check if inventory has at least the given stack (same type/id and count)
-- @param stack: StackComponent to check for
-- @return true if inventory contains at least this many items
function InventoryComponent.has(self, stack)
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

-- Check if can output (remove) the given stack from inventory
-- @param stack: StackComponent to remove
-- @return true if can remove all items
function InventoryComponent.can_output(self, stack)
    return self:has(stack)
end

-- Check if can input (add) the given stack to inventory
-- @param stack: StackComponent to add
-- @return true if can add all items
function InventoryComponent.can_input(self, stack)
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
            remaining = remaining - StackComponent.MAX_SIZE
            if remaining <= 0 then
                return true
            end
        end
    end

    return remaining <= 0
end

-- Input (add) a stack to inventory
-- @param stack: StackComponent to add
-- @return true if all items were added, false if some couldn't fit
function InventoryComponent.input(self, stack)
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
            local to_add = math.min(remaining, StackComponent.MAX_SIZE)
            self.slots[i] = StackComponent.new(stack:get_id(), to_add, stack:get_type())
            remaining = remaining - to_add
            if remaining <= 0 then
                return true
            end
        end
    end

    return remaining <= 0
end

-- Output (remove) a stack from inventory
-- @param stack: StackComponent describing what to remove
-- @return true if all items were removed, false if not enough items
function InventoryComponent.output(self, stack)
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
function InventoryComponent.get_slot(self, index)
    if index < 1 or index > self.size then
        return nil
    end
    return self.slots[index]
end

-- Set a stack at a specific slot index
function InventoryComponent.set_slot(self, index, stack)
    if index < 1 or index > self.size then
        return false
    end
    self.slots[index] = stack
    return true
end

-- Clear a slot
function InventoryComponent.clear_slot(self, index)
    return self:set_slot(index, nil)
end

-- Get total count of a specific item/block across all slots
function InventoryComponent.count(self, id, id_type)
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

-- Check if inventory is empty
function InventoryComponent.is_empty(self)
    for i = 1, self.size do
        if self.slots[i] ~= nil then
            return false
        end
    end
    return true
end

-- Check if inventory is full (no empty slots and all stacks full)
function InventoryComponent.is_full(self)
    for i = 1, self.size do
        local slot = self.slots[i]
        if slot == nil or not slot:is_full() then
            return false
        end
    end
    return true
end

-- Get number of empty slots
function InventoryComponent.empty_slots(self)
    local count = 0
    for i = 1, self.size do
        if self.slots[i] == nil then
            count = count + 1
        end
    end
    return count
end

return InventoryComponent

