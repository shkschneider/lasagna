# Lua eXtended (luax)

The `libraries/luax` module provides utility extensions to Lua's standard library. These are loaded globally at startup via `require "libraries.luax"`.

## Overview

luax extends Lua with commonly needed functionality that isn't in the standard library. All extensions are added to the global namespace or existing tables (`math`, `string`, `table`).

## Modules

### math.lua

Mathematical utility functions:

```lua
-- Constants
math.eps    -- Small epsilon value (1/1000)
math.inf    -- Infinity (math.huge or 9^9)

-- Functions
math.clamp(low, n, high)  -- Clamp n between low and high
math.lerp(from, to, t)    -- Linear interpolation
math.sign(n)              -- Returns -1, 0, or 1
math.round(n)             -- Round to nearest integer
```

**Examples:**
```lua
math.clamp(0, -5, 10)   -- 0 (clamped from -5)
math.clamp(0, 5, 10)    -- 5 (unchanged)
math.lerp(0, 100, 0.5)  -- 50
math.sign(-42)          -- -1
math.round(3.7)         -- 4
```

### string.lua

String utility functions:

```lua
string.contains(s, substr)  -- Check if string contains substring
string.starts(s, prefix)    -- Check if string starts with prefix
string.ends(s, suffix)      -- Check if string ends with suffix
string.trim(s)              -- Remove leading/trailing whitespace
string.title(s)             -- Title case (first letter of each word uppercase)
```

**Examples:**
```lua
string.contains("hello world", "wor")  -- true
string.starts("hello", "he")           -- true
string.ends("hello.lua", ".lua")       -- true
string.title("hello world")            -- "Hello World"
```

### table.lua

Table utility functions:

```lua
-- Compatibility
table.pack(...)         -- Pack arguments into table with n field
table.unpack(t)         -- Unpack table (alias for unpack)

-- Type checking
table.isarray(t)        -- Check if table is an array (integer keys only)

-- Conversion
table.tostring(t)       -- Convert table to string representation

-- Access
table.random(t)         -- Get random element from array
table.keys(t)           -- Get array of table keys
table.unique(t)         -- Remove duplicates from array
table.get(t, i)         -- Get element, supports negative indices
```

**Examples:**
```lua
table.isarray({1, 2, 3})        -- true
table.isarray({a = 1, b = 2})   -- false

table.tostring({a = 1, b = 2})  -- "{a=1,b=2}"
table.tostring({1, 2, 3})       -- "[1,2,3]"

local t = {"a", "b", "c"}
table.random(t)                  -- Random element
table.get(t, -1)                 -- "c" (last element)

table.unique({1, 2, 2, 3, 3})   -- {1, 2, 3}
```

### id.lua

Identifier generation:

```lua
id()    -- Generate a 7-hex short string
uuid()  -- Generate a UUID v4 string
```

**Example:**
```lua
local id = uuid()  -- "550e8400-e29b-41d4-a716-446655440000"
```

### random.lua

Random number generation:

```lua
random(n)      -- Same as math.random
random(m, n)   -- Random integer between m and n
```

Uses LÖVE's `love.math.random` when available for better randomness.

### async.lua

Coroutine-based async/await system for non-blocking operations:

```lua
-- Spawn an async task
local task = async(function(t)
    -- Do some work
    t:sleep(1)  -- Wait 1 second
    -- Continue after sleep
    return "done"
end)

-- In update loop
async.update(dt)

-- Check result
if task.result and task.result.status then
    print(task.result.data)  -- "done"
end
```

#### Task API

```lua
-- Create task
local task = async.spawn(fn, ...)

-- Inside task function
task:sleep(seconds)     -- Pause execution
task:await(other_task)  -- Wait for another task
task:cancel()           -- Cancel this task

-- Check status
task.result             -- nil if running, table if done
task.result.status      -- true if succeeded, false if failed
task.result.data        -- Return values (packed table)

-- Scheduler
async.update(dt)        -- Call in love.update
async.cancel(task)      -- Cancel a task
async.now()             -- Current scheduler time
```

**Example:**
```lua
-- Load resources asynchronously
local loader = async(function(t)
    print("Loading textures...")
    t:sleep(0.1)
    print("Loading sounds...")
    t:sleep(0.1)
    print("Done!")
    return { textures = {}, sounds = {} }
end)

-- Check in update
function love.update(dt)
    async.update(dt)
    if loader.result and loader.result.status then
        -- Loading complete
        local resources = loader.result.data[1]
    end
end
```

## Usage

luax is automatically loaded via `core/init.lua`:

```lua
require "libraries.luax"
```

All extensions become available globally. No need to require individual modules.
