local custom_colors = require "custom_colors"
local gpu = require "component".gpu --default gpu

local draw_char = " "
local font_ratio = 21/12 -- height of font / width of font (at 12 pt Calibri)
local drawingGPU = nil
local drawingTable = {}

--[[
  function to bind the passed gpu to be the drawing gpu  
  @return: true if the gpu is bound to draw else false
]]--
function drawingTable.bindDrawingGPU(gpu)
  if gpu == nil then 
    print("Trying to bind a NIL gpu to the drawing module") 
    return false
  end
  drawingGPU = gpu
  return true
end

function computeAspectRatio()
  local w, h = drawingGPU.getResolution()   
  return (h/w)*font_ratio
end

--[[
  draws a rectangle with the specific parameters  
  Note: the origin (0,0) is the upper-left corner of the screen
        color is an hex value 32 bit
]]--
function drawingTable.drawRectangle(x, y, xSize, ySize, color)
  local saved_color = drawingGPU.getBackground()
  drawingGPU.setBackground(color)
  drawingGPU.fill(x, y, xSize, ySize*computeAspectRatio(), draw_char)
  drawingGPU.setBackground(saved_color)
end

--[[ 
  wrapper for drawRectangle with same side size
]]--
function drawingTable.drawSquare(x, y, size, color)
  drawRectangle(x, y, size, size, color)
end

-- default initialization
drawingTable.bindDrawingGPU(gpu)

return drawingTable