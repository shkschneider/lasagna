-- Stack component
-- Represents a stack of items (max 64)

local StackComponent = {
    -- Maximum stack size
    MAX_SIZE = STACK_SIZE or 64,
}

-- Create a new stack
function StackComponent.new(id, count, id_type) -- TODO without id_type
    local stack = {
        id = "stack",
        item_id = nil,
        block_id = nil,
        count = count or 1,
    }
    -- Set the appropriate id field based on type
    if id_type == "item" then
        stack.item_id = id
    else
        stack.block_id = id
    end
    -- Clamp count to valid range
    stack.count = math.max(0, math.min(stack.count, StackComponent.MAX_SIZE))
    return setmetatable(stack, { __index = StackComponent })
end

-- Create an empty stack
function StackComponent.empty()
    return nil
end

-- Check if stack is empty
function StackComponent.is_empty(self)
    return self == nil or self.count <= 0
end

-- Check if stack is full
function StackComponent.is_full(self)
    return self.count >= StackComponent.MAX_SIZE
end

-- Get the id of this stack (block_id or item_id)
function StackComponent.get_id(self)
    return self.block_id or self.item_id
end

-- Get the type of this stack ("block" or "item")
function StackComponent.get_type(self)
    if self.item_id then
        return "item"
    elseif self.block_id then
        return "block"
    end
    return nil
end

-- Check if two stacks can be merged (same type and id)
function StackComponent.can_merge(self, other)
    if other == nil then
        return false
    end
    -- Must be same type (block or item) and same id
    if self.block_id and other.block_id then
        return self.block_id == other.block_id
    elseif self.item_id and other.item_id then
        return self.item_id == other.item_id
    end
    return false
end

-- Check if can add count items to this stack
function StackComponent.can_add(self, count)
    count = count or 1
    return self.count + count <= StackComponent.MAX_SIZE
end

-- Add items to this stack (returns number actually added)
function StackComponent.add(self, count)
    count = count or 1
    local space = StackComponent.MAX_SIZE - self.count
    local to_add = math.min(count, space)
    self.count = self.count + to_add
    return to_add
end

-- Remove items from this stack (returns number actually removed)
function StackComponent.remove(self, count)
    count = count or 1
    local to_remove = math.min(count, self.count)
    self.count = self.count - to_remove
    return to_remove
end

-- Split off a number of items into a new stack
function StackComponent.split(self, count)
    count = count or 1
    local removed = self:remove(count)
    if removed > 0 then
        return StackComponent.new(self:get_id(), removed, self:get_type())
    end
    return nil
end

-- Clone this stack
function StackComponent.clone(self)
    return StackComponent.new(self:get_id(), self.count, self:get_type())
end

-- Get available space in this stack
function StackComponent.space(self)
    return StackComponent.MAX_SIZE - self.count
end

-- String representation
function StackComponent.tostring(self)
    local id = self:get_id() or "?"
    local type_str = self:get_type() or "?"
    return string.format("Stack(%s:%s x%d)", type_str, id, self.count)
end

return StackComponent
