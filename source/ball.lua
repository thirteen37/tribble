import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx <const> = playdate.graphics

FRICTION = 0.5
THRESHOLD_V = 1
MIN_RADIUS = 5

Ball = {}

function Ball:new(x, y, a, v)
  local o = {x=x, y=y, a=a, v=v}
  setmetatable(o, self)
  self.__index = self
  o.t = playdate.getCurrentTimeMilliseconds()
  return o
end

function Ball:draw()
  gfx.fillCircleAtPoint(self.x, self.y, MIN_RADIUS)
end

function Ball:update()
  if self:isActive() then
    local dt = (playdate.getCurrentTimeMilliseconds() - self.t) / 1000
    local r = math.rad(self.a)
    local dy, dx = math.sin(r) * self.v * dt, math.cos(r) * self.v * dt
    self.x += dx
    self.y += dy
    self.v *= ((1 - FRICTION) * dt)
    if self.v < THRESHOLD_V then
      self.v = 0
    end
  end
end

function Ball:isActive()
  return self.v > 0
end
