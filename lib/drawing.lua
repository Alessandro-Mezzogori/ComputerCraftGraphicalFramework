local custom_colors = require "custom_colors"
local gpu = require "component".gpu --default gpu
local event = require "event"

-- module table
local drawing = {}

drawing.events = {
	REDRAW_SCENE="drawing_redrawscene",
	SET_SCENE="drawing_setscene",
	DARKEN_ELEMS="drawing_darkenelems",
	REDRAW_ELEMS="drawing_redrawelems",
}

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

local currentScene = 1  -- current index of displayed scene

--############### GPU FUNCTIONS ###############--
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
  local w, h = drawingGPU.getViewport()   
  return (h/w)*font_ratio
end

--############### DRAWING FUNCTIONS ###############--
--[[
  draws a rectangle with the specific parameters  
  Note: the origin (0,0) is the upper-left corner of the screen
        color is an hex value 32 bit
]]--
function drawRectangle(x, y, xSize, ySize, rectColor, text, textColor)
  local savedBGColor = drawingGPU.getBackground()
  local savedFGColor = drawingGPU.getForeground()
  drawingGPU.setBackground(rectColor or savedBGColor)
  drawingGPU.setForeground(textColor or savedFGColor)

  ySize = ySize*computeAspectRatio()
  drawingGPU.fill(x, y, xSize, ySize, draw_char)
  if type(text) == "string" then
  	drawingGPU.set(
  		math.floor(x + (xSize - string.len(text))/2), 
  		math.floor(y + ySize/2), 
  		text
  	)	
  end

  drawingGPU.setBackground(savedBGColor)
  drawingGPU.setForeground(savedFGColor)
end

--############### IS INSIDE FUNCTIONS ###############--
--[[ 
	all inside functions MUST HAVE the (px,py) pair that is being checked as the first and second param 
	the other params must be in the same order of it's creator function
	es: createRectangle(x, y, xSize, ySize) -> isInsideRectangle(px, py, x, y, xSize, ySize) 
]]--

--[[
	returns true if the point (px, py) is inside the rectangle with element id "eid" else returns false
]]--
function isInsideRectangle(px, py, x, y, xSize, ySize) 
	return (px >= x and px <= x + xSize) and (py >= y and py <= y + ySize)
end


--############### SCENE ###############--
function clearDrawingScreen()
	local w, h = drawingGPU.getViewport()
	drawingGPU.fill(1, 1, w, h, draw_char)
end

function redrawScene()
	-- if there's no scene stop redrawing
	if scenes[currentScene] == nil then return end

	-- clear screen
	clearDrawingScreen()
	-- for each element id call it's drawing function 
	redrawElements(scenes[currentScene])
end

function redrawElements(elementIDs)
	if elementIDs == nil then return end

	for _, eid in pairs(elementIDs) do
		elements[eid].drawingFunction(table.unpack(elements[eid].params))
	end
end

function drawing.drawingCleanUp()
	-- reset the current scene to the first
	setCurrentScene(1)

	-- deletes all scenes created
	local count = #scenes
	for i=0, count do scenes[i]=nil end

	-- deletes all elements created
	count = #elements
	for i=0, count do elements[i]=nil end 
end

--[[
	adds element to specific scene
	the scene is created if it wasn't
	@sceneID: 
		-can be either a table of ID's or one single ID
		-if nil it will be attached to the currentScene
	@elementID: 
		-can be either a table of ID's or one single ID
		-if nil nothing will be attached
]]--
function drawing.attachToScene(sceneID, elementID)
	sceneID = sceneID or currentScene
	local elementTable = {}
	local sceneTable = {}

	-- transform the parameters to tables
	if type(sceneID) ~= "table" then
		sceneTable[1] = sceneID
	else
		sceneTable = sceneID
	end

	if type(elementID) ~= "table" then
		elementTable[1] = elementID
	else
		elementTable = elementID
	end	

	-- iterate over the tables adding the contents of elementTable to sceneTable
	for _, scene in pairs(sceneTable) do
		for __, element in pairs(elementTable) do
			if scenes[scene] == nil then
				scenes[scene] = {element}
			else
				table.insert(scenes[scene], element)
			end
		end
	end
end

--[[
	sets the current scene to the passed sceneID 
	NOTE: doesn't check if the scene exists on setup so
	you may end up with a blank scene if nothings is added
]]--
function setCurrentScene(sceneID)
	currentScene = sceneID
end

--############### ELEMENT CREATION ###############--

function createElement(drawingFunction, ...)
	table.insert(
		elements, 
		{
			drawingFunction=drawingFunction, 
			insideFunction=isInsideRectangle, 
			darkened=false,
			params={...}
		}
	)
	return #elements
end

function drawing.createSquare(x, y, size, color, text, textColor)
	return createElement(drawRectangle, x, y, size, size, color, text, textColor)
end

function drawing.createRectangle(x, y, xSize, ySize, color, text, textColor)
	return createElement(drawRectangle, x, y, xSize, ySize, color, text, textColor)
end

--############### ELEMENT MANIPULATION ###############-- 

function drawing.getElementDescriptor(elementID)
	return elements[elementID]
end

--[[
	returns the current scene aka the table containing the elements id's of the active scene
]]--
function drawing.getActiveElementIDs()
	return scenes[currentScene]
end

--[[
	toggles the an element to become slightly darker or restores it to the original color
]]--
function toggleDarkenElement(elementIDs)
	if elements[elementID] == nil then return end
	local darkenRatio = 0.2

	for _, eid in pairs(elementIDs) do
		if elements[eid].darkened == false then
			elements[eid].params.color = custom_colors.darkenColor(elements[eid].params.color, darkenRatio)
		else
			elements[eid].params.color = custom_colors.darkenColor(elements[eid].params.color, 1/(1.0 - darkenRatio))
		end

	    elements[eid].darkened = not elements[eid].darkened
	end
end

--############### CONTROL FUNCTIONS ###############-- 
function drawing.isInsideElement(x, y, elementID)
	return elements[elementID].insideFunction(x, y, table.unpack(elements[elementID].params))
end

--############### THREAD ###############-- 
function handleDrawingEvent(eventID, ...)
	if eventID == drawing.events.REDRAW_SCENE then
		redrawScene(...)
	elseif eventID == drawing.events.SET_SCENE then
		setCurrentScene(...)
	elseif eventID == drawing.events.DARKEN_ELEMS then
		toggleDarkenElement({...})
	elseif eventID == drawing.events.REDRAW_ELEMS then
		redrawElements({...})
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