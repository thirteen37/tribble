function lrotate(x, n)
  return ((x<<n)&0xff) | (x>>(8-n))
end

function rotateArray(a, n)
  local b = {}
  for i, value in ipairs(a) do
	b[(i - n) % #a + 1] = value
  end
  return b
end
