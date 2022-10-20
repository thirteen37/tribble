import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx <const> = playdate.graphics
local geo <const> = playdate.geometry

local function drawZones()
  gfx.setLineWidth(2)
  gfx.setPattern({0xf0, 0xf0, 0xf0, 0xf0, 0x0f, 0x0f, 0x0f, 0x0f})
  gfx.drawLine(341, 240, 341, 0)
  gfx.setColor(gfx.kColorBlack)
  gfx.setLineWidth(1)
end

local function drawUI()
  drawZones()
  -- drawScore()
  -- drawTurret()
  -- drawGun()
  -- drawBlobs()
end

local function drawSplash()
  local accel_x, accel_y, accel_z = playdate.readAccelerometer()
  local angle = math.deg(math.atan(accel_y, accel_x))
  local isRotated = false
  if angle > -10 and angle < 10 then
    isRotated = true
  end
  local splashImage = gfx.image.new(200, 200, gfx.kColorWhite)
  gfx.pushContext(splashImage)
  gfx.drawText("The Trouble with", 0, 0)
  gfx.drawText("Tribology", 0, 30)
  if not isRotated then
    gfx.drawText("Rotate to start", 0, 60)
  end
  gfx.popContext()
  if isRotated then
    splashImage:drawRotated(110, 130, -90)
  else
    splashImage:draw(10, 10)
  end
end

local function promptCrank()
end

function playdate.update()
  playdate.startAccelerometer()
  repeat
    drawUI()
    drawSplash()
    if playdate.isCrankDocked() then
      promptCrank()
    end
    coroutine.yield()
  until playdate.buttonJustPressed(playdate.kButtonB)
  playdate.stopAccelerometer()
end
