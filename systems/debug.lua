local Debug = {
    id = "debug",
}

function Debug.load(self, debug)
    self.enabled = debug or (os.getenv("DEBUG") == "true")
end

function Debug.keypressed(self, key)
    if key == "backspace" then
        self.enabled = not self.enabled
    end
end

function Debug.draw(self)
    if self.enabled then
        local player = require("systems").get("player")
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(string.format("State: %s", G.components.state), 10, 120)
        love.graphics.print(string.format("Frames: %d/s", love.timer.getFPS()), 10, 100)
        love.graphics.print(string.format("TimeScale: %s", G.components.timescale:tostring()), 10, 140)
        
        -- Display player stance
        if player and player.components and player.components.stance then
            love.graphics.print(string.format("Stance: %s", player.components.stance.current), 10, 160)
        end
    end
end

return Debug
