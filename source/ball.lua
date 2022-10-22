import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx <const> = playdate.graphics

STATE_MOVING    = 1
STATE_GROW      = 2
STATE_GROWING   = 3
STATE_IDLE      = 4
STATE_EXPLODING = 5
STATE_DEAD      = 6

ELASTICITY  = 0.8
FRICTION    = 0.5
GROWTH_RATE = 100
MIN_RADIUS  = 10
THRESHOLD_S = playdate.display.getRefreshRate() -- At least 1 px movement
TIME_STEP   = 1 / playdate.display.getRefreshRate()

Ball = {}

function Ball:new(x, y, w, h, a, s, bs)
  local o = {x=x, y=y, w=w, h=h, a=a, s=s, bs=bs}
  setmetatable(o, self)
  self.__index = self
  o.r = MIN_RADIUS
  o.state = STATE_MOVING
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

local function ballCollisions(ball)
  for _, otherBall in pairs(ball.bs) do
	if otherBall ~= ball then
      local dx = ball.x - otherBall.x
      local dy = ball.y - otherBall.y
      local tr = otherBall.r + ball.r
      local intersectionSquared = (tr ^ 2) - (dx ^ 2 + dy ^ 2)
      if intersectionSquared > 0 then
        local normal = math.deg(math.atan(dy, dx))
        local incident = ball.a - (180 + normal)
        local reflected = (normal - incident) % 360
        ball.a = reflected
        local r = math.rad(ball.a)
        local dp = (intersectionSquared ^ 0.5) / 2
        local dy, dx = math.sin(r) * dp, math.cos(r) * dp
        ball.x += dx
        ball.y += dy
        ball.s *= ELASTICITY
      end
    end
  end
end

local function maxRadius(ball)
  local rs = {}
  for _, otherBall in pairs(ball.bs) do
    if otherBall ~= ball then
      local dx = ball.x - otherBall.x
      local dy = ball.y - otherBall.y
      local maxRadius = ((dx ^ 2) + (dy ^ 2)) ^ 0.5 - otherBall.r
      table.insert(rs, maxRadius)
    end
  end
  table.insert(rs, ball.x)
  table.insert(rs, ball.y)
  table.insert(rs, ball.w - ball.x)
  table.insert(rs, ball.h - ball.y)
  local min = rs[1]
  for _, r in pairs(rs) do
    if min > r then min = r end
  end
  return min
end

function Ball:update()
  if self.state == STATE_MOVING then
    local dt = TIME_STEP
    local r = math.rad(self.a)
    local dp = self.s * dt
    local dy, dx = math.sin(r) * dp, math.cos(r) * dp
    self.x += dx
    self.y += dy
    wallCollisions(self)
    ballCollisions(self)
    self.s = self.s - (self.s * FRICTION * dt)
    if self.s < THRESHOLD_S then
      self.s = 0
      self.x = math.floor(self.x)
      self.y = math.floor(self.y)
      self.state = STATE_GROW
    end
  elseif self.state == STATE_GROW then
    local r = math.floor(maxRadius(self))
    self.animator = gfx.animator.new(r / GROWTH_RATE * 1000, self.r, r, playdate.easingFunctions.outQuad)
    self.state = STATE_GROWING
  elseif self.state == STATE_GROWING then
    self.r = self.animator:currentValue()
    if self.animator:ended() then
      self.state = STATE_IDLE
    end
  end
end

function Ball:isActive()
  return self.state == STATE_MOVING or self.state == STATE_GROW or self.state == STATE_GROWING
end
