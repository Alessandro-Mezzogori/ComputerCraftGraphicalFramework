local computer = require("computer")
local event = require("event")

local helper_functions = {}

--[[
	forces the caller to wait <time> seconds
]]--
function helper_functions.wait(time)
	local stop = computer.uptime() + (time or 0)
	while computer.uptime() < stop do end
end

--[[
	concatenates the src table to the dest table and returns
	the dest table reference
]]--
function helper_functions.concatTable(dest, src)
	for i=1, #scr do
		dest[#dest + 1] = src[i]
	end
	return dest 
end

--[[
	wrapper functions for event.push so there's not need to import the event modules
]]
function helper_functions.pushEvent(eventID, ...)
	event.push(eventID, ...)
end

return helper_functions