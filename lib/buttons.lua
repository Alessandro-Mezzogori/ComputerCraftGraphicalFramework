local drawing = require "drawing"
local colors = require "custom_colors"
local eventManager = require "event_manager"
local helpers = require "helper_functions"


-- module's table
buttons = {}

-- element: drawingElementID: number, handler: function, pressed: bool, darken: bool
buttonMapping = {}

-- button functions 

function buttons.createButton(x, y, xSize, ySize, rectColor, text, textColor, handler, darkenOnPress)
  darkenOnPress = darkenOnPress or false

  local eid = drawing.createRectangle(x, y, xSize, ySize, rectColor, text, textColor)

  buttonMapping[eid] = {
    eid=eid, --doubled for easier access and readability
    handler=handler, 
    pressed=false, 
    darken=darkenOnPress
  }
  return eid
end

function updateButtonGUI(bd)
  if bd.darken and bd.pressed then
    helpers.pushEvent(drawing.events.DARKEN_ELEMS, bd.eid)
  end      
end


-- debug functions
function printButtonMapping()
  for k, v in pairs(buttonMapping) do
  	local str1 = "Button " .. tostring(k) .. " X: " .. tostring(v.x) .. " Y: " .. tostring(v.y) .. " "
  	local str2 = "W: " .. tostring(v.xSize) .. " H: " .. tostring(v.ySize) .. " HANDLER: " .. tostring(v.handler)
  	print(str1 .. str2)
  end
end   

-- managing functions

function buttons.buttonsHandlerDispatcher(playerName, screenX, screenY) -- prototype of touch event handler
  -- loop trough all the buttons and call the functino if screenX and screen Y are inside the boundaries
  for _, eid in pairs(drawing.getActiveElementIDs()) do    
    if (buttonMapping[eid] ~= nil) and (drawing.isInsideElement(screenX, screenY, eid)) and (buttonMapping[eid].pressed == false) then      
      buttonMapping[eid].pressed = true
      updateButtonGUI(buttonMapping[eid])
      
      buttonMapping[eid].handler(buttonDescriptor)
      
      buttonMapping[eid].pressed = false
      updateButtonGUI(buttonMapping[eid])
    end
  end
end

-- register the buttonsHandlerDispatcher in the background

return buttons