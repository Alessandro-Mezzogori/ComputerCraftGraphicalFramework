local custom_colors = require "custom_colors"
local gpu = require "component".gpu --default gpu
local event = require "event"

-- module table
local drawing = {}

-- module params
local draw_char = " "
local font_ratio = 21/12 -- height of font / width of font (at 12 pt Calibri)
local drawingGPU = nil
local runningEventLoop = false

local scenes = {} -- table containing all the scenes 
local currentScene = {} -- current displayed scene

--[[
  function to bind the passed gpu to be the drawing gpu  
  @return: true if the gpu is bound to draw else false
]]--
function drawing.bindDrawingGPU(gpu)
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
function drawing.drawRectangle(x, y, xSize, ySize, color)
  local saved_color = drawingGPU.getBackground()
  drawingGPU.setBackground(color)
  drawingGPU.fill(x, y, xSize, ySize*computeAspectRatio(), draw_char)
  drawingGPU.setBackground(saved_color)
end

--[[ 
  wrapper for drawRectangle with same side size
]]--
function drawing.drawSquare(x, y, size, color)
  drawing.drawRectangle(x, y, size, size, color)
end

-- thread functions 
function handleDrawingEvent(eventID, ...)
	if eventID == "drawing" then
		drawing.drawSquare(70, 20, 20, 0xFFFFFF)
	end
end

function drawing.stopEventLoop()
	runningEventLoop = false
end

function drawing.startEventLoop()
	runningEventLoop = true
	while runningEventLoop do
		handleDrawingEvent(event.pull()))
	end
end	

-- default initialization
drawing.bindDrawingGPU(gpu)

return drawing