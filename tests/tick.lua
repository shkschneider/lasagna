-- Test for Tick system
-- Run with: lua5.1 tests/tick.lua

-- Mock require for Tick
package.path = package.path .. ";./src/?.lua;./src/?/init.lua"
local Tick = require "game.tick"

local passed = 0
local failed = 0

local function test(name, func)
    local ok, err = pcall(func)
    if ok then
        print("[PASS] " .. name)
        passed = passed + 1
    else
        print("[FAIL] " .. name .. ": " .. tostring(err))
        failed = failed + 1
    end
end

-- Test 1: Create a tick
test("Create a tick", function()
    local count = 0
    local tick = Tick.new(10, function() count = count + 1 end)
    assert(tick ~= nil, "Tick should not be nil")
    assert(tick.n_ticks == 10, "Tick should have correct n_ticks")
    assert(tick.accumulated == 0, "Tick should start with 0 accumulated time")
end)

-- Test 2: Tick doesn't fire before threshold
test("Tick doesn't fire before threshold", function()
    local count = 0
    local tick = Tick.new(10, function() count = count + 1 end)
    
    -- Update for 0.5 seconds (5 ticks, need 10)
    tick:update(0.5)
    assert(count == 0, "Function should not have been called yet")
end)

-- Test 3: Tick fires at threshold
test("Tick fires at threshold", function()
    local count = 0
    local tick = Tick.new(10, function() count = count + 1 end)
    
    -- Update for 1.0 second (10 ticks)
    tick:update(1.0)
    assert(count == 1, "Function should have been called once")
end)

-- Test 4: Tick fires multiple times
test("Tick fires multiple times", function()
    local count = 0
    local tick = Tick.new(5, function() count = count + 1 end)
    
    -- Update for 1.0 second (10 ticks, should fire twice with 5 tick threshold)
    tick:update(1.0)
    assert(count == 2, "Function should have been called twice, got " .. count)
end)

-- Test 5: Reset works
test("Reset works", function()
    local count = 0
    local tick = Tick.new(10, function() count = count + 1 end)
    
    tick:update(0.5)
    tick:reset()
    assert(tick.accumulated == 0, "Accumulated should be reset to 0")
    
    tick:update(0.5)
    assert(count == 0, "Function should not fire after reset and partial update")
end)

-- Test 6: Progress tracking
test("Progress tracking", function()
    local tick = Tick.new(10, function() end)
    
    assert(tick:progress() == 0, "Progress should start at 0")
    
    tick:update(0.5)
    local progress = tick:progress()
    assert(progress > 0 and progress < 1, "Progress should be between 0 and 1, got " .. progress)
    
    tick:update(0.5)
    assert(tick:progress() == 0, "Progress should reset after firing")
end)

-- Test 7: Invalid parameters
test("Invalid parameters", function()
    local ok, err = pcall(function()
        Tick.new(-5, function() end)
    end)
    assert(not ok, "Should fail with negative n_ticks")
    
    ok, err = pcall(function()
        Tick.new(10, "not a function")
    end)
    assert(not ok, "Should fail with non-function parameter")
end)

print("\n" .. string.rep("-", 40))
print(string.format("Results: %d passed, %d failed", passed, failed))
print(string.rep("-", 40))

os.exit(failed > 0 and 1 or 0)
