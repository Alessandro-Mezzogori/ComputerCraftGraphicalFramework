local event_manager = require "event_manager"
local buttons = require "buttons"

local gfm = {}

function gfm.start()
	event_manager.registerEventHandler("touch", buttons.buttonsHandlerDispatcher)
	event_manager.startEventLoop()
end

return gfm