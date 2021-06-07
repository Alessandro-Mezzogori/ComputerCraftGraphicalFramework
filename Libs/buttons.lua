local drawing = require "drawing"
local colors = require "custom_colors"
local eventManager = require "event_manager"
local helpers = require "helper_functions"


-- module's table
buttons = {}

-- element: x:number , y:number , xSize: number, ySize: number, color: color, handler: function, pressed: bool, darken: bool
button_mapping = {}

-- button functions 

function buttons.createButton(x, y, xSize, ySize, color, handler, darkenOnPress)
  darkenOnPress = darkenOnPress or false

  table.insert(
    button_mapping, 
    {
      x=x, 
      y=y, 
      xSize=xSize, 
      ySize=ySize, 
      color=color, 
      handler=handler, 
      pressed=false, 
      darken=darkenOnPress
  	}
  )
  drawing.drawRectangle(x, y, xSize, ySize, color)
end

function updateButtonGUI(bd)
  if bd.darken == true then
    if bd.pressed == true then 
      drawing.drawRectangle(bd.x, bd.y, bd.xSize, bd.ySize, colors.darkenColor(bd.color, 0.2))
    else
      drawing.drawRectangle(bd.x, bd.y, bd.xSize, bd.ySize, bd.color)
    end
  end      
end


-- debug functions
function printButtonMapping()
  for k, v in pairs(button_mapping) do
    print("Button " .. tostring(k) .. " X: " .. tostring(v[1]) .. " Y: " .. tostring(v[2]) .. " W: " .. tostring(v[3]) .. " H: " .. tostring(v[4]) .. " HANDLER: " .. tostring(v[5]))
  end
end   

-- managing functions
function insideButtonBoundary(screenX, screenY, bd) -- bd = buttonDescriptor
  -- buttonDescriptor is an element of the buttonMapping table
  if (screenX >= bd.x and screenX <= bd.x + bd.xSize) and (screenY >= bd.y and screenY <= bd.y + bd.ySize) then
    return true
  end
  return false
end

function buttons.buttonsHandlerDispatcher(playerName, screenX, screenY) -- prototype of touch event handler
  -- loop trough all the buttons and call the functino if screenX and screen Y are inside the boundaries
  for _, buttonDescriptor in ipairs(button_mapping) do    
    if (insideButtonBoundary(screenX, screenY, buttonDescriptor)) and ( buttonDescriptor.pressed == false) then      
      buttonDescriptor.pressed = true
      updateButtonGUI(buttonDescriptor)
      
      buttonDescriptor.handler(buttonDescriptor)
      
      buttonDescriptor.pressed = false
      updateButtonGUI(buttonDescriptor)
    end
  end
end

-- register the buttonsHandlerDispatcher in the background

return buttons