import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/timer"

import "ball.lua"

local gfx <const> = playdate.graphics
local geo <const> = playdate.geometry

SCREEN_WIDTH, SCREEN_HEIGHT = playdate.display.getSize()
DMZ_WIDTH = 60

local powerlineTimer = playdate.timer.new(500, 0, 8)
powerlineTimer.repeats = true

local function drawZones()
  gfx.setLineWidth(2)
  gfx.setPattern({0x66, 0x66, 0x33, 0x33, 0x66, 0x66, 0x33, 0x33})
  gfx.drawLine(SCREEN_WIDTH - DMZ_WIDTH, SCREEN_HEIGHT, SCREEN_WIDTH - DMZ_WIDTH, 0)
  gfx.setColor(gfx.kColorBlack)
  gfx.setLineWidth(1)
end

local function lrotate(x, n)
  return ((x<<n)&0xff) | (x>>(8-n))
end

local function rotateArray(a, n)
  local b = {}
  for i, value in ipairs(a) do
	b[(i - n) % #a + 1] = value
  end
  return b
end

local function calculateTurretAngle()
  local crankAngle = playdate.getCrankPosition()
  local angle = nil
  if crankAngle <= 180 then
    angle = 180 - crankAngle
  else
    angle = crankAngle - 180
  end
  return math.min(170, math.max(10, angle))
end

local function drawTurret()
  gfx.setColor(gfx.kColorWhite)
  gfx.fillCircleAtPoint(SCREEN_WIDTH - 20, SCREEN_HEIGHT / 2, 20 + 10)
  gfx.setColor(gfx.kColorBlack)
  gfx.fillCircleAtPoint(SCREEN_WIDTH - 20, SCREEN_HEIGHT / 2, 20)
  gfx.fillRect(SCREEN_WIDTH - 20, SCREEN_HEIGHT / 2 - 20, 20, 40)
  gfx.setLineWidth(4)
  local offset = math.floor(powerlineTimer.value)
  gfx.setPattern({
      lrotate(0x0f, offset),
      lrotate(0x0f, offset),
      lrotate(0x0f, offset),
      lrotate(0x0f, offset),
      lrotate(0xf0, offset),
      lrotate(0xf0, offset),
      lrotate(0xf0, offset),
      lrotate(0xf0, offset),
  })
  gfx.drawLine(SCREEN_WIDTH, SCREEN_HEIGHT - 10, SCREEN_WIDTH - 16, SCREEN_HEIGHT - 10)
  gfx.setPattern(rotateArray({0x0f, 0x0f, 0x0f, 0x0f, 0xf0, 0xf0, 0xf0, 0xf0}, offset))
  gfx.drawLine(SCREEN_WIDTH - 18, SCREEN_HEIGHT - 10, SCREEN_WIDTH - 18, SCREEN_HEIGHT / 2 + 20)
  gfx.setColor(gfx.kColorBlack)
  gfx.setLineWidth(1)
  local turretPoly = geo.rect.new(-10, 20-4, 20, 12):toPolygon()
  local turretTransform = geo.affineTransform.new()
  turretTransform:rotate(calculateTurretAngle())
  turretTransform:translate(SCREEN_WIDTH - 20, SCREEN_HEIGHT / 2)
  turretTransform:transformPolygon(turretPoly)
  gfx.fillPolygon(turretPoly)
end

local function drawUI()
  drawZones()
  -- drawScore()
  drawTurret()
end

local function isRotated()
  local accel_x, accel_y, accel_z = playdate.readAccelerometer()
  local angle = math.deg(math.atan(accel_y, accel_x))
  return angle > -10 and angle < 10
end

local function drawSplash()
  local splashImage = gfx.image.new(200, 200, gfx.kColorWhite)
  gfx.pushContext(splashImage)
  gfx.drawText("The Trouble with", 0, 0)
  gfx.drawText("Tribology", 0, 30)
  if not isRotated() then
    gfx.drawText("Rotate to start", 0, 60)
  end
  gfx.popContext()
  if isRotated() then
    splashImage:drawRotated(110, 130, -90)
  else
    splashImage:draw(10, 10)
  end
end

local function promptCrank()
  local w, h = gfx.getTextSize("Use crank")
  local promptImage = gfx.image.new(w, h, gfx.kColorWhite)
  if isRotated() and playdate.isCrankDocked() then
    gfx.pushContext(promptImage)
    gfx.drawText("Use crank", 0, 0)
    gfx.popContext()
  end
  promptImage:drawRotated(SCREEN_WIDTH - 22 - (h / 2) - 5, (SCREEN_HEIGHT * 0.75), -90)
end

local function activeBall(balls)
  for _, ball in pairs(balls) do
    if ball:isActive() then
      return true
    end
  end
  return false
end

local function updateAndDrawBalls(balls)
  local ballImage = gfx.image.new(SCREEN_HEIGHT, SCREEN_WIDTH)
  gfx.pushContext(ballImage)
  -- clean dirty balls
  for _, ball in pairs(balls) do
    if ball:isActive() then
      ball:erase()
    end
  end
  -- move balls
  for _, ball in pairs(balls) do
    ball:update()
  end
  -- draw balls
  for _, ball in pairs(balls) do
    ball:draw()
  end
  gfx.popContext()
  ballImage:drawRotated(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, -90)
end

function playdate.update()
  -- Home screen
  playdate.startAccelerometer()
  repeat
    drawSplash()
    promptCrank()
    drawUI()

    playdate.timer.updateTimers()
    coroutine.yield()
  until playdate.buttonIsPressed(playdate.kButtonB) and isRotated() and not playdate.isCrankDocked()
  playdate.stopAccelerometer()
  gfx.clear()
  -- Game
  local inProgress = true
  local balls = {}
  while inProgress do
    if playdate.buttonIsPressed(playdate.kButtonB) and not activeBall(balls) then
      -- create new ball
      local newBall = Ball:new(SCREEN_HEIGHT / 2, SCREEN_WIDTH - 20,
                               SCREEN_HEIGHT, SCREEN_WIDTH - DMZ_WIDTH,
                               (calculateTurretAngle() + 180) % 360, 400,
                               balls)
      table.insert(balls, newBall)
    end

    updateAndDrawBalls(balls)
    drawUI()

    playdate.timer.updateTimers()
    coroutine.yield()
  end
  -- End game
end
