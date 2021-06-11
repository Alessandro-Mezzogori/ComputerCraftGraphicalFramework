local custom_colors = require "custom_colors"
local event = require "event"
local helpers = require "helper_functions"

--[[
	README:
		before doing anything with the drawing module functions
		the function setUp must be called to prevent any unknown behaviour
]]--

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


--############### SET UP FUNCTIONS ###############--
--[[
	sets up all the params to avoid behaviours
]]-- 
function drawing.setUp(gpu)
	local defaultGPU = require "component".gpu --default gpu
	drawing.bindDrawingGPU(gpu or defaultGPU)
	drawing.drawingCleanUp()
end

--############### DRAWING FUNCTIONS ###############--
--[[
  draws a rectangle with the specific parameters  
  Note: the origin (0,0) is the upper-left corner of the screen
        color is an hex value 32 bit
]]--
function drawRectangle(x, y, xSize, ySize)
  drawingGPU.fill(x, y, xSize, ySize, draw_char)
end

function drawTextRectangle(params)
  local savedBGColor = drawingGPU.getBackground()
  local savedFGColor = drawingGPU.getForeground()
  drawingGPU.setForeground(params.textColor or savedFGColor)
  drawingGPU.setBackground(params.color or savedBGColor)

  drawRectangle(params.x, params.y, params.xSize, params.ySize)
  if type(params.text) == "string" then
  	drawingGPU.set(
  		math.floor(params.x + (params.xSize - string.len(params.text))/2), 
  		math.floor(params.y + params.ySize/2), 
  		params.text
  	)	
  end
  drawingGPU.setForeground(savedFGColor)
  drawingGPU.setBackground(savedBGColor)
end

function drawSlider(params)
  -- draw external triangle
  local savedBGColor = drawingGPU.getBackground()

  drawingGPU.setBackground(params.rectColor or savedBGColor)
  drawRectangle(params.x, params.y, params.xSize, params.ySize)

  drawingGPU.setBackground(params.sliderColor or savedBGColor)  
  drawRectangle(params.sX, params.sY, params.sXSize*params.sliderFill, params.sYSize)

  drawingGPU.setBackground(savedBGColor)
end

--############### IS INSIDE FUNCTIONS ###############--
--[[ 
	all inside functions MUST HAVE:
		-the (px,py) pair that is being checked as the first and second param 
		-a params table
]]--

--[[
	returns true if the point (px, py) is inside the rectangle with element id "eid" else returns false
]]--
function isInsideRectangle(px, py, params) 
	local x, y, xSize, ySize = params.x, params.y, params.xSize, params.ySize
	return (px >= x and px <= x + xSize) and (py >= y and py <= y + ySize)
end

function isInsideSlider(px, py, params)
	local x, y, xSize, ySize = params.x, params.y, params.xSize, params.ySize
	return (px >= x and px <= x + xSize) and (py >= y and py <= y + ySize)
end

--############### GET COLOR FUNCTIONS ###############--
--[[
	all the functions contained in this section provide the function to retrieve the color 
	from the params arguments of the element descriptor
]]--
function getColorRectangle(params)
	return params.color
end

function getColorSlider(params)
	return params.sliderColor
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
		if eid == nil or elements[eid] == nil then goto continue end

		elements[eid].drawingFunction(elements[eid].params)

		::continue::
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
	@returns: the number of elements attached to the scene
]]--
function drawing.attachToScene(sceneID, elementID)
	if elementID == nil then return false end

	sceneID = sceneID or currentScene
	local elementTable = helpers.toTable(elementID)
	local sceneTable = helpers.toTable(sceneID)
	local countAttached = 0
	-- iterate over the tables adding the contents of elementTable to sceneTable
	for _, scene in pairs(sceneTable) do
		if scenes[scene] == nil then
			scenes[scene] = elementTable
		else
			helpers.concatTable(scenes[scene], elementTable)
		end
		countAttached = countAttached + #elementTable
	end

	return countAttached
end

--[[
	detach an elemen from a scene
	@sceneID: 
		-can be either a table of ID's or one single ID
		-if nil it will be attached to the currentScene
	@elementID: 
		-can be either a table of ID's or one single ID
		-if nil nothing will be attached
	@returns: the number of elements detached to the scene
]]--
function drawing.detachFromScene(sceneID, elementID)
	if elementID == nil then return end
	
	sceneID = sceneID or currentScene
	local elementTable = helpers.toTable(elementID)
	local sceneTable = helpers.toTable(sceneID)
	local countDetached = 0
	for _, sid in pairs(sceneTable) do
		for __, elem in pairs(elementTable) do
			for ___, eid in ipairs(scenes[sid])  do
				if eid == elem then 
					scenes[___] = nil 
					countDetached = countDetached + 1
				end
			end
		end
	end

	return countDetached
end

--[[
	sets the current scene to the passed sceneID 
	NOTE: doesn't check if the scene exists on setup so
	you may end up with a blank scene if nothings is added
]]--
function setCurrentScene(sceneID)
	currentScene = sceneID
end

--[[
	returns the scene with the passed sceneID
	NOTE: can return nil, control is delegated to caller
]]--
function getScene(sceneID)
	return scenes[sceneID]
end

--############### ELEMENT CREATION ###############--

function createElement(drawingFunction, insideFunction, getColor, params)
	table.insert(
		elements, 
		{
			drawingFunction=drawingFunction, 
			insideFunction=insideFunction, 
			darkened=false,
			getColor=getColor,
			params=params,
		}
	)

	return #elements
end

function drawing.createRectangle(x, y, xSize, ySize, rectColor, text, textColor)
	-- it is needed to multiply the ySize of all elements to the aspectRatio of the viewport 
	-- to maintain the ratio between xsize and ysize in the actual screen
	return createElement(
		drawTextRectangle, 
		isInsideRectangle,
		getColorRectangle,
		{x=x, y=y, xSize=xSize, ySize=(ySize*computeAspectRatio()), color=rectColor, text=text, textColor=textColor}
	)
end

function drawing.createSquare(x, y, size, color, text, textColor)
	return drawing.createRectangle(x, y, size, size, color, text, textColor)
end

function drawing.createSlider(x, y, xSize, ySize, rectColor, sliderColor, sliderFill, marginX, marginY)
	-- params control and preparation 
	sliderFill = math.min(sliderFill, 1.0)
	marginX, marginY = (marginX or 0.03), (marginY or 0.03)
	ySize = ySize*computeAspectRatio()

	marginX, marginY = math.floor((x + xSize)*marginX), math.floor((y + ySize)*marginY)
	return createElement(
		drawSlider,
		isInsideSlider,
		getColorSlider,
		{
			x=x, y=y, xSize=xSize, ySize=ySize, 
			sX=(x+marginX), sY=(y+marginY), sXSize=(xSize-2*marginX), sYSize=(ySize-2*marginY), 
			rectColor=rectColor, sliderColor=sliderColor,
			sliderFill = sliderFill
		}
	)
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
	local darkenRatio = 0.2
	for _, eid in pairs(elementIDs) do
		if elements[eid] == nil then goto continue end
		
	    --print(elements[eid].params.color)
		if elements[eid].darkened == false then
			elements[eid].params.color = custom_colors.darkenColor(elements[eid].params.color, darkenRatio)
		else
			elements[eid].params.color = custom_colors.darkenColor(elements[eid].params.color, -darkenRatio/(1.0 - darkenRatio))
		end

		elements[eid].darkened = not elements[eid].darkened
	    ::continue::
	end
end

--############### CONTROL FUNCTIONS ###############-- 
function drawing.isInsideElement(x, y, elementID)
	return elements[elementID].insideFunction(x, y, elements[elementID].params)
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
	if drawingGPU == nil then 
		print("Need to bind drawing gpu before starting the drawingEventLoop")
		os.exit(-1)
	end

	-- first draw 
	redrawScene(currentScene)

	runningEventLoop = true
	while runningEventLoop do
		handleDrawingEvent(event.pull())
	end
end	

return drawing