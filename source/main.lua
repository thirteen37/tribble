import "CoreLibs/animation"
import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/timer"

import "ball.lua"
import "maskops.lua"

local gfx <const> = playdate.graphics
local geo <const> = playdate.geometry

local SCREEN_WIDTH, SCREEN_HEIGHT = playdate.display.getSize()
local DMZ_WIDTH = 60
local CRANK_PERIOD = 3000

local STATE_SPLASH   = 1
local STATE_PLAY     = 2
local STATE_GAMEOVER = 3
local state

local powerlineTimer = playdate.timer.new(500, 0, 8)
powerlineTimer.repeats = true

local function drawZones()
  gfx.setLineWidth(2)
  gfx.setPattern({0x66, 0x66, 0x33, 0x33, 0x66, 0x66, 0x33, 0x33})
  gfx.drawLine(SCREEN_WIDTH - DMZ_WIDTH, SCREEN_HEIGHT, SCREEN_WIDTH - DMZ_WIDTH, 0)
  gfx.setColor(gfx.kColorBlack)
  gfx.setLineWidth(1)
end

local turretAnimator
local function calculateTurretAngle()
  if playdate.isCrankDocked() then
    if not turretAnimator then
      turretAnimator = gfx.animator.new(CRANK_PERIOD, 170, 10)
      turretAnimator.reverses = true
      turretAnimator.repeatCount = -1
    end
    return turretAnimator:currentValue()
  else
    turretAnimator = nil
    local crankAngle = playdate.getCrankPosition()
    local angle = nil
    if crankAngle <= 180 then
      angle = 180 - crankAngle
    else
      angle = crankAngle - 180
    end
    return math.min(170, math.max(10, angle))
  end
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

gfx.setFont(gfx.font.new("fonts/Block"))
local score = 0
local hiScore = 0
local function drawScore()
  local _, h = gfx.getTextSize("Score")
  local w = 18
  local scoreImage = gfx.image.new(w, h)
  gfx.pushContext(scoreImage)
  gfx.drawText(score, 0, 0)
  gfx.popContext()
  scoreImage = scoreImage:scaledImage(2)
  gfx.pushContext(scoreImage)
  gfx.drawTextAligned("Score", w*2, 0, kTextAlignment.right)
  gfx.popContext()
  scoreImage:scaledImage(2):drawRotated(SCREEN_WIDTH - 44, SCREEN_HEIGHT - w*2 - 4, -90)
  w = 25
  local scoreImage = gfx.image.new(w, h)
  gfx.pushContext(scoreImage)
  gfx.drawTextAligned(hiScore, w-1, 0, kTextAlignment.right)
  gfx.popContext()
  scoreImage = scoreImage:scaledImage(2)
  gfx.pushContext(scoreImage)
  gfx.drawText("Hi-Score", 0, 0)
  gfx.popContext()
  scoreImage:scaledImage(2):drawRotated(SCREEN_WIDTH - 44, w*2, -90)
end

local function saveHiScore()
  local ds = {
    hiScore = hiScore
  }
  playdate.datastore.write(ds)
end

local function loadHiScore()
  local ds = playdate.datastore.read()
  hiScore = (ds and ds["hiScore"]) or 0
end
loadHiScore()

local function drawUI()
  drawZones()
  drawTurret()
  drawScore()
end

local function isRotated()
  local accel_x, accel_y, accel_z = playdate.readAccelerometer()
  local xAngle = math.deg(math.atan((accel_x ^ 2 + accel_y ^ 2) ^ 0.5, accel_z))
  if xAngle > 45 then
    local zAngle = math.deg(math.atan(accel_y, accel_x))
    return zAngle > -20 and zAngle < 20
  else
    return true
  end
end

local rotateAnimation = gfx.animation.loop.new(nil, gfx.imagetable.new("images/rotate"))
local function drawSplash()
  local splashImage = gfx.image.new(240, 240, gfx.kColorWhite)
  gfx.pushContext(splashImage)
  gfx.image.new("images/splash"):draw(15, 50)
  if not isRotated() then
    local w, h = gfx.getTextSize("Rotate screen\nto start")
    local rotateText = gfx.image.new(w, h)
    gfx.pushContext(rotateText)
    gfx.drawTextAligned("Rotate screen\nto start", w, 0, kTextAlignment.right)
    gfx.popContext()
    rotateText:scaledImage(2):draw(105, 180)
    rotateAnimation:draw(210, 175)
  end
  gfx.popContext()
  if isRotated() then
    splashImage:drawRotated(140, 120, -90)
  else
    splashImage:draw(20, 0)
  end
end

local function fastInOut(t, b, c, d)
  local a = t / d * math.pi
  local x = (math.cos(a) + 1) / 2
  return x * c + b
end

local crankPromptAnimator
local function promptCrank()
  local w, h = gfx.getTextSize("Crank it!")
  local promptImage = gfx.image.new(w, h, gfx.kColorWhite)
  if not crankPromptAnimator then
    crankPromptAnimator = gfx.animator.new(1500, h, -h, fastInOut)
    crankPromptAnimator.repeatCount = -1
  end
  if playdate.isCrankDocked() then
    gfx.pushContext(promptImage)
    gfx.drawText("Crank it!", 0, crankPromptAnimator:currentValue())
    gfx.popContext()
  else
    crankPromptAnimator = nil
  end
  promptImage:scaledImage(2):drawRotated(SCREEN_WIDTH - (h / 2) - 5, (SCREEN_HEIGHT * 0.75) + 3, -90)
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
  local ballImage = gfx.image.new(SCREEN_HEIGHT, SCREEN_WIDTH, gfx.kColorWhite)
  gfx.pushContext(ballImage)
  -- move balls
  for _, ball in pairs(balls) do
    ball:update()
  end
  -- draw balls
  for _, ball in pairs(balls) do
    ball:draw()
  end
  -- prune dead balls
  for i, ball in pairs(balls) do
    if ball:isDead() then
      balls[i] = nil
    end
  end
  gfx.popContext()
  ballImage:drawRotated(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, -90)
end

local function drawGameOver()
  local splashImage = gfx.image.new("images/gameover")
  gfx.setImageDrawMode("NXOR")
  splashImage:drawRotated(160, 130, -90)
  gfx.setImageDrawMode("copy")
end

local function buttonPressed()
  return (playdate.buttonJustPressed(playdate.kButtonB) or playdate.buttonJustPressed(playdate.kButtonA))
end

local function splash()
  drawSplash()
  drawUI()
  promptCrank()
  return buttonPressed() and isRotated()
end

local balls = {}
local newBall = nil
local function play()
  if buttonPressed() and not activeBall(balls) then
    -- create new ball
    newBall = Ball:new(SCREEN_HEIGHT / 2, SCREEN_WIDTH - 20,
                       SCREEN_HEIGHT, SCREEN_WIDTH - DMZ_WIDTH,
                       (calculateTurretAngle() + 180) % 360, 400,
                       balls)
    table.insert(balls, newBall)
  end

  updateAndDrawBalls(balls)
  drawUI()
  promptCrank()

  -- score kills
  for _, ball in pairs(balls) do
    if ball ~= newBall and ball:isDying() then
      score += 1
      if score > hiScore then
        hiScore = score
        saveHiScore()
      end
    end
  end

  -- if our new ball died, it's game over
  if newBall and newBall:isDying() then
    for _, ball in pairs(balls) do
      ball:explode()
    end
    return true
  else
    return false
  end
end

local function gameOver()
  updateAndDrawBalls(balls)
  drawUI()
  drawGameOver()
  return buttonPressed()
end

function playdate.update()
  if state == nil then
    playdate.startAccelerometer()
    state = STATE_SPLASH
  end
  if state == STATE_SPLASH then
    if splash() then
      playdate.stopAccelerometer()
      gfx.clear()
      score = 0
      state = STATE_PLAY
    end
  end
  if state == STATE_PLAY then
    if play() then
      state = STATE_GAMEOVER
    end
  end
  if state == STATE_GAMEOVER then
    if gameOver() then
      balls = {}
      newBall = nil
      gfx.clear()
      playdate.startAccelerometer()
      state = STATE_SPLASH
    end
  end
  playdate.timer.updateTimers()
end
