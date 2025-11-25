-- Coroutine scheduler
--
-- Async:
--   async(function(t) end)
--   task = async.spawn(function(t) ... end)
--     task:sleep(1)
--     if task.result then return end
--     task:await(another)
--   end)
--   async.update(dt)
--   async.cancel(t)
--
-- Task:
--   task:status() (boolean)
--   task:cancel()
--   task:sleep(secs)
--   task:await(another)
--   task.result.status (boolean)
--   task.result.data (table)
--

local async = {}

local now = 0
local tasks = {} -- list of task objects

local function result_ok(data)
    return { status = true, data = data or {} }
end

local function result_ko()
    return { status = false, data = nil }
end

local function task_new(fn)
    local task = {
        co = nil, -- coroutine
        result = nil, -- table.pack
        _wake = now, -- internal 'clock'
        _waiters = nil,
        _args = nil,   -- table.pack of initial resume args (task + extra args)
        _values = nil, -- table.pack of values to resume with (used for await)
    }

    function task.sleep(self, secs)
        assert(coroutine.running(), "task.sleep must be called inside a task coroutine")
        assert(type(self) == "table" and self.co, "use task:sleep()")
        return coroutine.yield({ sleep = tonumber(secs) or 0 })
    end

    function task.await(self, other)
        assert(coroutine.running(), "task.await must be called inside a task coroutine")
        assert(type(self) == "table" and self.co, "use task:await()")
        assert(type(other) == "table" and other.co, "task.await expects a task object")
        -- yield a wait descriptor; scheduler will resume this coroutine with (ok, unpack(other.result))
        local _, r = coroutine.yield({ wait = other })
        return r
    end

    function task.cancel(self)
        assert(type(self) == "table" and self.co, "use task:cancel()")
        self.result = result_ko()
    end

    -- create coroutine wrapper that calls fn(task, ...)
    task.co = coroutine.create(function(...)
        return fn(...)
    end)

    return task
end

local function task_finish(task, ok, ...)
    task.result = ok and result_ok(table.pack(...)) or result_ko()
    -- _wake _waiters: schedule them and set their _values to (ok, unpack(result))
    if task._waiters then
        for _, waiter_co in ipairs(task._waiters) do
            for _, t in ipairs(tasks) do
                if t.co == waiter_co and not t.done then
                    t._values = table.pack(ok, table.unpack(task.result, 1, task.result.n))
                    t._wake = now
                    break
                end
            end
        end
        task._waiters = nil
    end
end

local function resume_task(task)
    if task.done then return false, nil end

    local resume_pack = task._values or task._args
    task._values = nil
    task._args = nil

    local ok, a, b, c, d
    if resume_pack then
        ok, a, b, c, d = coroutine.resume(task.co, table.unpack(resume_pack, 1, resume_pack.n))
    else
        ok, a, b, c, d = coroutine.resume(task.co)
    end

    if not ok then
        task_finish(task, false, a) -- a is error message
        return false, nil
    end

    if coroutine.status(task.co) == "dead" then
        task_finish(task, true, a, b, c, d)
        return false, nil
    end

    -- yielded: return packed yielded values
    return true, table.pack(a, b, c, d)
end

function async.spawn(fn, ...)
    assert(type(fn) == "function", "async.spawn expects a function")
    local task = task_new(fn)
    local args = table.pack(...)
    task._args = table.pack(task, table.unpack(args, 1, args.n))
    table.insert(tasks, task)
    return task
end

-- callable sugar: async(fn, ...) -> spawn(fn, ...)
setmetatable(async, {
    __call = function(self, fn, ...)
        return self.spawn(fn, ...)
    end
})

function async.cancel(task)
    if type(task) ~= "table" or not task.co then return false end
    task.result = result_ko()
end

-- scheduler update: call from your main loop (love.update)
function async.update(dt)
    now = now + (dt or 0)

    local i = 1
    while i <= #tasks do
        local task = tasks[i]
        if task.result and task.result.status then
            table.remove(tasks, i)
        elseif task._wake <= now then
            local still_running, yielded_pack = resume_task(task)
            if not still_running then
                table.remove(tasks, i)
            else
                local desc = yielded_pack[1]
                if desc == nil then
                    task._wake = now
                elseif type(desc) == "table" then
                    if desc.sleep then
                        local s = tonumber(desc.sleep) or 0
                        task._wake = now + s
                    elseif desc.wait then
                        local target = desc.wait
                        assert(type(target) == "table" and target.co, "async: wait expects a task")
                        if target.result and target.result.status then
                            -- target already done: resume immediately with (ok, ...)
                            task._values = table.pack(target.ok, table.unpack(target.result or {}, 1, (target.result and target.result.n) or 0))
                            task._wake = now
                        else
                            target._waiters = target._waiters or {}
                            table.insert(target._waiters, task.co)
                            -- don't schedule task now; it will be resumed when target finishes
                        end
                    else
                        task._wake = now
                    end
                else
                    error("async: yielded unsupported value; yield a control table or nil")
                end
                i = i + 1
            end
        else
            i = i + 1
        end
    end
end

function async.now() return now end

return async
