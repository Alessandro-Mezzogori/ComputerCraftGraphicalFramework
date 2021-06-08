local computer = require("computer")

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

return helper_functions