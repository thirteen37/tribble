import "CoreLibs/animator"

local gfx <const> = playdate.graphics

DEFAULT_COUNT = 20
DEFAULT_DURATION = 1000
DEFAULT_SCALE = 10
SPEED_FACTOR = 20

Sparks = {}

function Sparks:new(x, y, w, h, n, t, s)
  local o = {x=x, y=y, w=w, h=h}
  setmetatable(o, self)
  self.__index = self
  o.i = gfx.image.new(w, h)
  gfx.pushContext(o.i)
  for i = 1, (n or DEFAULT_COUNT) do
    gfx.drawPixel(math.random(w), math.random(h))
  end
  gfx.popContext()
  o.a = gfx.animator.new(t or DEFAULT_DURATION, 0, s or DEFAULT_SCALE, playdate.easingFunctions.outCubic)
  return o
end

function Sparks:draw()
  local ended = false
  gfx.setImageDrawMode("NXOR")
  if not self.a:ended() then
    if self.li then
      self.li:drawCentered(self.lx, self.ly)
    end
    local a = self.a:currentValue()
    self.li = self.i:scaledImage(a):blurredImage(a, 1, gfx.image.kDitherTypeScreen, true)
    self.lx = self.x
    self.ly = self.y + a * SPEED_FACTOR
    self.li:drawCentered(self.lx, self.ly)
  else
    if self.li then
      self.li:drawCentered(self.lx, self.ly)
    end
    self.li = nil
    ended = true
  end
  gfx.setImageDrawMode("copy")
  return not ended
end
