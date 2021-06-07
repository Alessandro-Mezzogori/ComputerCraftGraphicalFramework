local event_manager = require "event_manager"
local buttons = require "buttons"

local gfm = {}

function gfm.start()	
	if isEventHandlerRegistered("touch", buttons.buttonsHandlerDispatcher) == false then
		event_manager.registerEventHandler("touch", buttons.buttonsHandlerDispatcher)
  	end

	event_manager.startEventLoop()
end

return gfm