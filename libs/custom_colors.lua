local bit32 = require "bit32"

custom_colors = {}

custom_colors.BLUE = 0x296eb4
custom_colors.DARK_PURPLE = 0x37123c

function getRGB(color)
  local r = bit32.rshift(bit32.band(color, 0xFF0000), 16)
  local g = bit32.rshift(bit32.band(color, 0x00FF00), 8)
  local b = bit32.band(color, 0x0000FF)
  return {r, g, b}
end

function getHEX(rgbTable)
  return bit32.lshift(rgbTable[1], 16) + bit32.lshift(rgbTable[2], 8) + rgbTable[3]
end

function custom_colors.darkenColor(color, percentage)
  rgbValue = getRGB(color)
  for _, component in ipairs(rgbValue) do
    rgbValue[_] = math.floor(component - component*percentage)
  end

  return getHEX(rgbValue)  
end

return custom_colors