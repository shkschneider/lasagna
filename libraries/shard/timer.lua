-- https://github.com/MineGame159/shard

local Timer = {}
Timer.__index = Timer

-- duration (number) callback (function)
function Timer.new(self, duration, callback)
  local timer = {}
  setmetatable(timer, Timer)
  timer.duration = duration or 1
  timer.progress = 0
  timer.callback = callback
  return timer
end

function Timer.update(self, deltaTime)
    self.progress = self.progress + (deltaTime or 0)
    if self.progress > self.duration then
        self.progress = self.progress - self.duration
        self.callback()
    end
end

return Timer
