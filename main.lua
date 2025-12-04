assert(love and jit)
require "libs.luax"
require "core"
dassert = dassert or assert
Log = require "libs.log"

LAYER_MIN = 1
LAYER_DEFAULT = 2
LAYER_MAX = 2
BLOCK_SIZE = 16
STACK_SIZE = 64

G = require("src.game")
G.NAME = "Lasagna"
G.VERSION = { major = 0, minor = 4, patch = nil, tostring = function(self)
    return string.format("%d.%d.%s", self.major, self.minor, tostring(self.patch or "x"))
end }

function love.load() G:load() end
function love.update(dt) G:update(dt) end
function love.draw() G:draw() end
function love.keypressed(key) G:keypressed(key) end
function love.keyreleased(key) G:keyreleased(key) end
function love.mousepressed(x, y, button) G:mousepressed(x, y, button) end
function love.mousereleased(x, y, button) G:mousereleased(x, y, button) end
function love.mousemoved(x, y, dx, dy) G:mousemoved(x, y, dx, dy) end
function love.wheelmoved(x, y) G:wheelmoved(x, y) end
function love.textinput(text) G:textinput(text) end
function love.resize(width, height) G:resize(width, height) end
function love.focus(focused) G:focus(focused) end
function love.quit() G:quit() end
