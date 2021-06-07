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

-- array of elements aka {<drawing function>, <table of params>} -> the id of the entry is the element id
local elements = {
}

-- table containing all the scenes, a scene is an array of element id's
local scenes = {
} 

local currentScene = 1  -- current idnex of displayed scene

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
function drawRectangle(x, y, xSize, ySize, color)
  local saved_color = drawingGPU.getBackground()
  drawingGPU.setBackground(color)
  drawingGPU.fill(x, y, xSize, ySize*computeAspectRatio(), draw_char)
  drawingGPU.setBackground(saved_color)
end

--############### SCENE ###############--
function redrawScene()
	-- TODO add a clear screen function
	-- for each element id call it's drawing function 
	for _, elementID in ipairs(scenes[currentScene]) do
		elements[elementID].drawingFunction(table.unpack(elements[elementID].params))
	end
end

function drawingCleanUp()
	local count = #scenes
	for i=0, count do scenes[i]=nil end

	count = #elements
	for i=0, count do elements[i]=nil end 
end

--[[
	adds element to specific scene
	the scene is created if it wasn't
]]--
function attachToScene(sceneID, elementID)
	if scenes[sceneID] == nil
		scenes[sceneID] = {elementID}
	else
		table.insert(scenes, elementID)
	end
end

function setCurrentScene(sceneID)
	currentScene = sceneID
end

--############### ELEMENTS ###############--
function createElement(drawingFunction, ...)
	table.insert(elements, {drawingFunction=drawingFunction, ...})
	return #elements
end

function drawing.createSquare(x, y, size, color)
	createElement(drawRectangle, x, y, size, size, color)
end

function drawing.createRectangle(x, y, xSize, ySize, color)
	createElement(drawRectangle, x, y, xSize, ySize, color)
end

--############### THREAD ###############-- 
function handleDrawingEvent(eventID, ...)
	if eventID == "drawing" then
		redrawScene()
	end

	if eventID == "drawing_setscene" then
		setCurrentScene(...)
	end
end

function drawing.stopEventLoop()
	runningEventLoop = false
end

function drawing.startEventLoop()
	-- bind the current gpu to be the drawer
	drawing.bindDrawingGPU(gpu)

	runningEventLoop = true
	while runningEventLoop do
		handleDrawingEvent(event.pull())
	end
end	

return drawing