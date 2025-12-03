local Stack = {
    id = "stack",
    MAX_SIZE = STACK_SIZE or 64,
    -- TODO tostring
}

-- Create a new stack
function Stack.new(id, count, id_type) -- TODO without id_type
    local stack = {
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
    stack.count = math.max(0, math.min(stack.count, Stack.MAX_SIZE))
    return setmetatable(stack, { __index = Stack })
end

-- Create an empty stack
function Stack.empty()
    return nil
end

-- Check if stack is empty
function Stack.is_empty(self)
    return self == nil or self.count <= 0
end

-- Check if stack is full
function Stack.is_full(self)
    return self.count >= Stack.MAX_SIZE
end

-- Get the id of this stack (block_id or item_id)
function Stack.get_id(self)
    return self.block_id or self.item_id
end

-- Get the type of this stack ("block" or "item")
function Stack.get_type(self)
    if self.item_id then
        return "item"
    elseif self.block_id then
        return "block"
    end
    return nil
end

-- Check if two stacks can be merged (same type and id)
function Stack.can_merge(self, other)
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
function Stack.can_add(self, count)
    count = count or 1
    return self.count + count <= Stack.MAX_SIZE
end

-- Add items to this stack (returns number actually added)
function Stack.add(self, count)
    count = count or 1
    local space = Stack.MAX_SIZE - self.count
    local to_add = math.min(count, space)
    self.count = self.count + to_add
    return to_add
end

-- Remove items from this stack (returns number actually removed)
function Stack.remove(self, count)
    count = count or 1
    local to_remove = math.min(count, self.count)
    self.count = self.count - to_remove
    return to_remove
end

-- Split off a number of items into a new stack
function Stack.split(self, count)
    count = count or 1
    local removed = self:remove(count)
    if removed > 0 then
        return Stack.new(self:get_id(), removed, self:get_type())
    end
    return nil
end

-- Clone this stack
function Stack.clone(self)
    return Stack.new(self:get_id(), self.count, self:get_type())
end

-- Get available space in this stack
function Stack.space(self)
    return Stack.MAX_SIZE - self.count
end

-- String representation
function Stack.tostring(self)
    local id = self:get_id() or "?"
    local type_str = self:get_type() or "?"
    return string.format("Stack(%s:%s x%d)", type_str, id, self.count)
end

return Stack
