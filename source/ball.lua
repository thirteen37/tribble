import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx <const> = playdate.graphics

FRICTION = 0.5
ELASTICITY = 0.8
THRESHOLD_S = playdate.display.getRefreshRate() -- At least 1 px movement
MIN_RADIUS = 10

Ball = {}

function Ball:new(x, y, w, h, a, s)
  local o = {x=x, y=y, w=w, h=h, a=a, s=s}
  setmetatable(o, self)
  self.__index = self
  o.t = playdate.getCurrentTimeMilliseconds()
  o.r = MIN_RADIUS
  return o
end

function Ball:draw()
  gfx.fillCircleAtPoint(self.x, self.y, self.r)
end

function Ball:erase()
  gfx.setColor(gfx.kColorWhite)
  gfx.fillCircleAtPoint(self.x, self.y, self.r)
  gfx.setColor(gfx.kColorBlack)
end

local function wallCollisions(ball)
  -- left
  if ball.x < ball.r then
    ball.x = ball.r + (ball.r - ball.x)
    assert(ball.a > 90 and ball.a < 270, "invalid x approach: " .. ball.a)
    if ball.a < 180 then
      ball.a = 180 - ball.a
    else
      ball.a = 360 - (ball.a - 180)
    end
    ball.s *= ELASTICITY
  end
  -- top
  if ball.y < ball.r then
    ball.y = ball.r + (ball.r - ball.y)
    assert(ball.a > 180, "invalid y approach: " .. ball.a)
    if ball.a < 270 then
      ball.a = 180 - (ball.a - 180)
    else
      ball.a = 360 - ball.a
    end
    ball.s *= ELASTICITY
  end
  -- right
  if ball.x > ball.w - ball.r then
    ball.x = (ball.w - ball.r) - (ball.x - (ball.w - ball.r))
    assert(ball.a < 90 or ball.a > 270, "invalid x approach: " .. ball.a)
    if ball.a < 90 then
      ball.a = 90 + (90 - ball.a)
    else
      ball.a = 270 - (ball.a - 270)
    end
    ball.s *= ELASTICITY
  end
  -- bottom
  ball.a = ball.a % 360
end

function Ball:update()
  if not self:isActive() then return end
  local dt = (playdate.getCurrentTimeMilliseconds() - self.t) / 1000
  local r = math.rad(self.a)
  local dp = self.s * dt
  local dy, dx = math.sin(r) * dp, math.cos(r) * dp
  self.x += dx
  self.y += dy
  wallCollisions(self)
  self.s = self.s - (self.s * FRICTION * dt)
  if self.s < THRESHOLD_S then
    self.s = 0
  end
  self.t = playdate.getCurrentTimeMilliseconds()
end

function Ball:isActive()
  return self.s > 0
end
