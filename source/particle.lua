import "CoreLibs/animator"

local gfx <const> = playdate.graphics

DEFAULT_DURATION = 1000
DEFAULT_SCALE = 10

Sparks = {}

function Sparks:new(x, y, w, h, t, s)
  local o = {x=x, y=y, w=w, h=h}
  setmetatable(o, self)
  self.__index = self
  local n = (w + h) // 2
  o.i = gfx.image.new(3, 3)
  gfx.pushContext(o.i)
  gfx.drawPixel(1, 1)
  gfx.popContext()
  o.s = {}
  for _ = 1, n do
    table.insert(o.s, {math.random(-w/2, w/2), math.random(-h/2, h/2)})
  end
  t = t or DEFAULT_DURATION
  s = s or DEFAULT_SCALE
  o.sa = gfx.animator.new(t, 0, s, playdate.easingFunctions.outCubic)
  o.ba = gfx.animator.new(t / 2, 0, s, playdate.easingFunctions.outCubic, t / 2)
  return o
end

function Sparks:draw()
  gfx.setImageDrawMode("NXOR")
  if not self.sa:ended() and not self.ba:ended() then
    local s = self.sa:currentValue()
    local b = self.ba:currentValue()
    local i = self.i:scaledImage(s):blurredImage(b, 1, gfx.image.kDitherTypeFloydSteinberg, true)
    for _, value in pairs(self.s) do
      local x, y = value[1], value[2]
      i:drawCentered(self.x + x * s, self.y + y * s)
    end
    return true
  else
    return false
  end
  gfx.setImageDrawMode("copy")
end
