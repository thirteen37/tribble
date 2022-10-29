import "CoreLibs/animator"

local gfx <const> = playdate.graphics

DEFAULT_DURATION = 1000
DEFAULT_SCALE = 10

local sparkImage <const> = gfx.image.new(3,3)
gfx.pushContext(sparkImage)
gfx.drawLine(0, 1, 2, 1)
gfx.drawLine(1, 0, 1, 2)
gfx.popContext()

Sparks = {}

function Sparks:new(x, y, w, h, t, s, b)
  local o = {x=x, y=y, w=w, h=h}
  setmetatable(o, self)
  self.__index = self
  local n = (w + h) // 2
  o.s = {}
  local w2, h2 = w / 2, h / 2
  for _ = 1, n do
    table.insert(o.s, {math.random(-w2, w2), math.random(-h2, h2)})
  end
  t = t or DEFAULT_DURATION
  s = s or DEFAULT_SCALE
  b = b or s
  o.sa = gfx.animator.new(t, 0, s, playdate.easingFunctions.outCubic)
  o.ba = gfx.animator.new(t, 1, b, playdate.easingFunctions.outCubic)
  return o
end

function Sparks:draw()
  gfx.setImageDrawMode("NXOR")
  if not self.sa:ended() and not self.ba:ended() then
    local s = self.sa:currentValue()
    local b = self.ba:currentValue()
    local i = sparkImage:scaledImage(b):blurredImage(b, 1, gfx.image.kDitherTypeFloydSteinberg, true)
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
