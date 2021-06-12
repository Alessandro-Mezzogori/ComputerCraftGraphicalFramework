local drawing = require "drawing"
local colors = require "custom_colors"
local eventManager = require "event_manager"
local helpers = require "helper_functions"

--[[
  the buttons.lua module houses the logic for all components that can be touched
  -buttons
  -lists
  -sliders
]]--

-- module's table
local buttons = {}

-- element: drawingElementID: number, handler: function, pressed: bool, darken: bool
local touchableMapping = {}

--############### MODULE HANDLERS ###############--


--############### TOUCHABLE CREATION ###############--
function createTouchable(elementId, handler, darkenOnPress, params)
  darkenOnPress = darkenOnPress or false

  touchableMapping[elementId] = {
    eid=elementId, --doubled for easier access and readability
    handler=handler, 
    pressed=false, 
    darken=darkenOnPress,
    params=params -- params for the handler function
  }
  return elementId
end

function buttons.createButton(x, y, xSize, ySize, rectColor, text, textColor, handler, darkenOnPress)
  local eid = drawing.createRectangle(x, y, xSize, ySize, rectColor, text, textColor)
  return createTouchable(eid, handler, darkenOnPress)
end

function updateButtonGUI(bd)
  if bd.darken then
    helpers.pushEvent(drawing.events.DARKEN_ELEMS, bd.eid)
  end     
    
  helpers.pushEvent(drawing.events.REDRAW_ELEMS, bd.eid)
end

--############### SLIDER ###############--
function sliderGeneralHandler(bd, playerName, screenX, screenY)
  local ed = drawing.getElementDescriptor(bd.eid)
  -- if the direction is horizontal use X, if not default to vertical direction
  local sliderFill = (ed.params.direction == drawing.directions.HORIZONTAL) and (screenX - ed.params.sX)/ed.params.sXSize
  sliderFill = sliderFill or 1.0 - (screenY - ed.params.sY)/ed.params.sYSize  
  
  bd.params.sliderFill = math.min(1.0, math.max(0.0, sliderFill))
  ed.params.sliderFill = bd.params.sliderFill
  -- call to assigned handler
  bd.params.handler(bd)
end

function buttons.createSlider(x, y, xSize, ySize, rectColor, sliderColor, handler, direction, sliderFill, marginX, marginY)
  local eid = drawing.createSlider(x, y, xSize, ySize, rectColor, sliderColor, direction, sliderFill, marginX, marginY)
  return createTouchable(eid, sliderGeneralHandler, false, {handler=handler, direction=direction, sliderFill=sliderFill})
end


--############### DEBUG FUNCTIONS ###############--

function printTouchableMapping()
  for k, v in pairs(touchableMapping) do
  	local str1 = "Button EID: " .. tostring(k) .. " " 
  	local str2 = " HANDLER: " .. tostring(v.handler) .. " darkenOnPress: " ..tostring(v.darken)
  	print(str1 .. str2)
    print("PARAMS: ", table.unpack(v.params))
  end
end   

--############### MANAGING FUNCTIONS ###############--

function buttons.buttonsHandlerDispatcher(playerName, screenX, screenY) -- prototype of touch event handler
  -- loop trough all the buttons and call the functino if screenX and screen Y are inside the boundaries
  for _, eid in pairs(drawing.getActiveElementIDs()) do    
    if (touchableMapping[eid] ~= nil) and (drawing.isInsideElement(screenX, screenY, eid)) and (touchableMapping[eid].pressed == false) then      
      touchableMapping[eid].pressed = true
      updateButtonGUI(touchableMapping[eid])
      
      touchableMapping[eid].handler(touchableMapping[eid], playerName, screenX, screenY)
      
      touchableMapping[eid].pressed = false
      updateButtonGUI(touchableMapping[eid])
    end
  end
end

return buttons