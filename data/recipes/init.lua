-- Recipe System
-- Central registry for all crafting recipes

local Recipes = {
    ages = require "data.recipes.ages",
}

-- Get recipe for upgrading to a specific age
-- @param target_age: The age to upgrade to (1, 2, 3, 4)
-- @return recipe table or nil if not found
function Recipes.get_age_recipe(target_age)
    for _, recipe in ipairs(Recipes.ages) do
        if recipe.age == target_age then
            return recipe
        end
    end
    return nil
end

-- Check if player has required materials for a recipe
-- @param recipe: Recipe table with inputs
-- @param inventory: Inventory object to check
-- @return true if all inputs are available
function Recipes.can_craft(recipe, inventory)
    if not recipe or not recipe.inputs then
        return false
    end
    
    for _, input in ipairs(recipe.inputs) do
        local count = inventory:count(input.id, input.type)
        if count < input.count then
            return false
        end
    end
    
    return true
end

-- Consume materials from inventory for a recipe
-- @param recipe: Recipe table with inputs
-- @param inventory: Inventory object to consume from
-- @return true if materials were consumed successfully
function Recipes.consume_inputs(recipe, inventory)
    if not Recipes.can_craft(recipe, inventory) then
        return false
    end
    
    -- Consume all inputs
    for _, input in ipairs(recipe.inputs) do
        local Stack = require "src.entities.stack"
        local stack = Stack.new(input.id, input.count, input.type)
        if not inventory:give(stack) then
            -- This shouldn't happen if can_craft returned true
            return false
        end
    end
    
    return true
end

-- Add recipe outputs to inventory
-- @param recipe: Recipe table with outputs
-- @param inventory: Inventory object to add to
-- @return true if all outputs were added
function Recipes.add_outputs(recipe, inventory)
    if not recipe or not recipe.outputs then
        return true
    end
    
    for _, output in ipairs(recipe.outputs) do
        local Stack = require "src.entities.stack"
        local stack = Stack.new(output.id, output.count, output.type)
        if not inventory:take(stack) then
            return false
        end
    end
    
    return true
end

return Recipes
