local System = {
    priority = 0,
    components = {},
}

function System.load(self, ...) end
function System.update(self, dt) end
function System.draw(self) end

return System
