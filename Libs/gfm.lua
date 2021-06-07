local event_manager = require "event_manager"
local buttons = require "buttons"
local thread = require "thread"
local drawing = require "drawing"

local gfm = {}

function gfm.start()	
	if isEventHandlerRegistered("touch", buttons.buttonsHandlerDispatcher) == false then
		event_manager.registerEventHandler("touch", buttons.buttonsHandlerDispatcher)
  	end

  	-- start drawing thread
  	if isEventHandlerRegistered("touch", drawing.stopEventLoop) == false then
		event_manager.registerEventHandler("touch", drawing.stopEventLoop)
  	end

  	local drawingThread = thread.create(
  		drawing.startEventLoop
  	)
  	-- become the event thread 
	event_manager.startEventLoop()

	-- cleanup 
	drawingThread:kill()
end

return gfm