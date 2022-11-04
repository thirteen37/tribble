import "CoreLibs/animator"

local gfx <const> = playdate.graphics
local geo <const> = playdate.geometry

DEFAULT_DURATION = 1000
DEFAULT_SCALE = 10
FRAGMENT_JITTER = 2

local sparkImage <const> = gfx.image.new(3,3)
gfx.pushContext(sparkImage)
gfx.drawLine(0, 1, 2, 1)
gfx.drawLine(1, 0, 1, 2)
gfx.popContext()

Sparks = {}

function Sparks:new(x, y, w, h, t, s)
  local o = {x=x, y=y}
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
  o.sa = gfx.animator.new(t, 0, s, playdate.easingFunctions.outCubic)
  o.ba = gfx.animator.new(t, 0, 1, playdate.easingFunctions.outCubic)
  return o
end

function Sparks:draw()
  gfx.setImageDrawMode("NXOR")
  if not self.sa:ended() and not self.ba:ended() then
    local s = self.sa:currentValue()
    local b = self.ba:currentValue()
    local i = sparkImage:scaledImage(b)
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

Fragments = {}

function Fragments:new(x, y, w, h, t, s)
  local o = {x=x, y=y, w=w+(2*FRAGMENT_JITTER), h=h+(2*FRAGMENT_JITTER)}
  setmetatable(o, self)
  self.__index = self
  local n = (w + h) // 4
  o.f = {}
  local w2, h2 = w / 2, h / 2
  for _ = 1, n do
    local x, y = math.random(-w2, w2), math.random(-h2, h2)
    local p = geo.polygon.new(3)
    for i = 1, 3 do
      p:setPointAt(i, math.random(x-FRAGMENT_JITTER, x+FRAGMENT_JITTER), math.random(y-FRAGMENT_JITTER, y+FRAGMENT_JITTER))
    end
    p:close()
    table.insert(o.f, p)
  end
  t = t or DEFAULT_DURATION
  s = s or DEFAULT_SCALE
  o.sa = gfx.animator.new(t, 0, s, playdate.easingFunctions.outCubic)
  return o
end

function Fragments:draw()
  if not self.sa:ended() then
    local s = self.sa:currentValue()
    gfx.setColor(gfx.kColorXOR)
    for _, p in pairs(self.f) do
      local t = geo.affineTransform.new()
      t:scale(s)
      t:translate(self.x, self.y)
      gfx.fillPolygon(t:transformedPolygon(p))
    end
    gfx.setColor(gfx.kColorBlack)
    return true
  else
    return false
  end
end
